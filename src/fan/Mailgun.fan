//
// Copyright (c) 2013, Andy Frank
// Licensed under the MIT License
//
// History:
//   12 Apr 2013  Andy Frank  Creation
//

using email
using util
using web

**
** Mailgun API
**
const class Mailgun
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Constructor.
  new make(|This|? f := null)
  {
    if (f != null) f(this)
    this.apiBase = `https://api.mailgun.net/v2/$domain`
    this.apiSend = `$apiBase/messages`
    this.apiLog  = `$apiBase/log`
    this.apiUnsubscribes = `$apiBase/unsubscribes`
  }

  ** API key for your Mailgun account.
  const Str apiKey

  ** Domain to use for your Mailgun account.
  const Str domain

  ** Optional default address to use for 'From' header if
  ** not specified in `send` or `sendEmail`.
  const Str? from

//////////////////////////////////////////////////////////////////////////
// Sending
//////////////////////////////////////////////////////////////////////////

  **
  ** Send message using given params. See Mailgun documentation
  ** for available parameters:
  **
  ** `http://documentation.mailgun.net/api-sending.html`
  **
  **   send([
  **     "from":    "Test <me@example.com>",
  **     "to":      "foo@example.com, bar@example.com",
  **     "subject": "Test Message!",
  **     "text":    "Hey there!",
  **   ])
  **
  **  Returns response from Mailgun if successful.  Throws Err
  **  if fails for any reason.
  **
  **  Note: file attachments are not yet supported.
  **
  Str:Obj send(Str:Obj params)
  {
    // default 'from' if not specified
    if (!params.containsKey("from") && from != null) params["from"] = from
    return invoke("POST", apiSend, params)
  }

  ** Convenience to use an [Email]`email::Email` instance for `send`.
  Str:Obj sendEmail(Email email)
  {
    params := Str:Obj[:]

    // recpts
    if (email.from != null) params["from"] = email.from
    if ((email.to?.size  ?: 0) > 0) params["to"]   = email.to.join(", ")
    if ((email.cc?.size  ?: 0) > 0) params["cc"]   = email.cc.join(", ")
    if ((email.bcc?.size ?: 0) > 0) params["bcc"]  = email.bcc.join(", ")

    // subject
    params["subject"] = email.subject

    // body
    parts := EmailPart[,]
    parts.addAll(email.body is MultiPart
      ? ((MultiPart)email.body).parts
      : [email.body])
    parts.each |p|
    {
      if (p is TextPart)
      {
        tp   := (TextPart)p
        html := p.headers.any |v| { v.contains("text/html") }
        params[html ? "html" : "text"] = tp.text
      }
      // TODO FIXTI: FilePart
    }

    return send(params)
  }

//////////////////////////////////////////////////////////////////////////
// Unsubscribes
//////////////////////////////////////////////////////////////////////////

  **
  ** Get list of unsubscribes.
  **  - limit: Max number of records to return, or null for Mailgun default
  **  - skip:  Number of records to skip, or null for Mailgun default
  **
  ** See Mailgun documentation for unsubscribes:
  **
  ** `http://documentation.mailgun.net/api-unsubscribes.html`
  **
  [Str:Obj][] unsubscribes(Int? limit := null, Int? skip := null)
  {
    params := Str:Str[:]
    if (limit != null) params["limit"] = limit.toStr
    if (skip  != null) params["skip"] = skip.toStr
    return invoke("GET", apiUnsubscribes, params)
  }

  **
  ** Get a single unsubscribe record. Returns response from Mailgun
  ** if successful. Throws Err if fails for any reason.
  **
  ** See Mailgun documentation for unsubscribes:
  **
  ** `http://documentation.mailgun.net/api-unsubscribes.html`
  **
  [Str:Obj][] getUnsubscribe(Str address)
  {
    invoke("GET", `$apiUnsubscribes/$address`)
  }

  **
  ** Add address to unsubscribe table. Returns response from Mailgun
  ** if successful. Throws Err if fails for any reason.
  **
  ** See Mailgun documentation for unsubscribes:
  **
  ** `http://documentation.mailgun.net/api-unsubscribes.html`
  **
  Str:Obj addUnsubscribe(Str address, Str tag := "*")
  {
    invoke("POST", apiUnsubscribes, ["address":address, "tag":tag])
  }

  **
  ** Remove an address from unsubscribe table. Returns response from
  ** Mailgun if successful. Throws Err if fails for any reason.
  **
  ** See Mailgun documentation for unsubscribes:
  **
  ** `http://documentation.mailgun.net/api-unsubscribes.html`
  **
  Str:Obj removeUnsubscribe(Str addressOrId)
  {
    invoke("DELETE", `$apiUnsubscribes/$addressOrId`)
  }

//////////////////////////////////////////////////////////////////////////
// Logs
//////////////////////////////////////////////////////////////////////////

  **
  ** Get log entries for this Mailgun account.
  **  - limit: Max number of records to return, or null for Mailgun default
  **  - skip:  Number of records to skip, or null for Mailgun default
  **
  ** See Mailgun documentation for log:
  **
  ** `http://documentation.mailgun.net/api-logs.html`
  **
  [Str:Obj][] log(Int? limit := null, Int? skip := null)
  {
    params := Str:Str[:]
    if (limit != null) params["limit"] = limit.toStr
    if (skip  != null) params["skip"] = skip.toStr
    return invoke("GET", apiLog, params)
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  ** Invoke a REST callback with given arguments.
  private Obj invoke(Str method, Uri uri, [Str:Str]? params := null)
  {
    WebClient? c
    try
    {
      if (method == "GET" && params != null) uri = uri.plusQuery(params)

      // init client
      c = WebClient(uri)
      c.reqHeaders["Authorization"] = "Basic " + "api:$apiKey".toBuf.toBase64

      // send/rec
      [Str:Obj]? res
      switch (method)
      {
        case "GET":    res = parseJson(c.getStr)
        case "DELETE": c.reqMethod="DELETE"; c.writeReq; c.readRes; res=parseJson(c.resStr)
        case "POST":   c.postForm(params); res=parseJson(c.resStr)
        default: throw ArgErr("Unsupported method $method")
      }

      // check response
      if (c.resCode != 200) throw Err(res["message"] ?: "")

      // return results
      return res.containsKey("items")
        ? ((Obj[])res["items"]).map |v| { toMap(v) }
        : toMap(res)
    }
    finally c?.close
  }

  ** Parse JSON response.
  private Str:Obj parseJson(Str res) { JsonInStream(res.in).readJson }

  ** Convert JSON map to Fantom types.
  private Str:Obj toMap(Str:Obj json)
  {
    json.map |v| { DateTime.fromHttpStr(v as Str ?: "", false) ?: v }
  }

  private const Uri apiBase
  private const Uri apiSend
  private const Uri apiLog
  private const Uri apiUnsubscribes
}
