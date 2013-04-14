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
    if (!params.containsKey("from")) params["from"] = from

    WebClient? c
    try
    {
      // post msg
      c = client(apiSend)
      c.postForm(params)

      // check response
      map := fromMap(JsonInStream(c.resStr.in).readJson)
      if (c.resCode != 200) throw Err(map["message"] ?: "")

      // looks good
      c.close
      return map
    }
    finally c?.close
  }

  ** Convenience to use an [Email]`email::Email` instance for `send`.
  Void sendEmail(Email email)
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

    send(params)
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

    WebClient? c
    try
    {
      // post msg
      c = client(apiUnsubscribes.plusQuery(params))
      res := c.getStr

      // check response
      if (c.resCode != 200)
      {
        map := fromMap(JsonInStream(res.in).readJson)
        throw Err(map["message"] ?: "")
      }

      // parse resp
      c.close
      return fromList(JsonInStream(res.in).readJson)
    }
    finally c?.close
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
    WebClient? c
    try
    {
      // post msg
      c = client(`$apiUnsubscribes/$address`)
      res := c.getStr

      // check response
      if (c.resCode != 200)
      {
        map := fromMap(JsonInStream(res.in).readJson)
        throw Err(map["message"] ?: "")
      }

      // parse resp
      c.close
      return fromList(JsonInStream(res.in).readJson)
    }
    finally c?.close
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
    WebClient? c
    try
    {
      // post msg
      c = client(apiUnsubscribes)
      c.postForm([
        "address": address,
        "tag": tag
      ])

      // check response
      map := fromMap(JsonInStream(c.resStr.in).readJson)
      if (c.resCode != 200) throw Err(map["message"] ?: "")

      // parse resp
      c.close
      return map
    }
    finally c?.close
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
    WebClient? c
    try
    {
      // post msg
      c = client(`$apiUnsubscribes/$addressOrId`)
      c.reqMethod = "DELETE"
      c.writeReq
      c.readRes

      // check response
      map := fromMap(JsonInStream(c.resStr.in).readJson)
      if (c.resCode != 200) throw Err(map["message"] ?: "")

      // parse resp
      c.close
      return map
    }
    finally c?.close
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

    WebClient? c
    try
    {
      // post msg
      c = client(apiLog.plusQuery(params))
      res := c.getStr

      // check response
      if (c.resCode != 200)
      {
        map := fromMap(JsonInStream(res.in).readJson)
        throw Err(map["message"] ?: "")
      }

      // parse resp
      c.close
      return fromList(JsonInStream(res.in).readJson)
    }
    finally c?.close
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  ** Get an authentication WebClient instance.
  private WebClient client(Uri uri)
  {
    c := WebClient(uri)
    c.reqHeaders["Authorization"] = "Basic " + "api:$apiKey".toBuf.toBase64
    return c
  }

  ** Convert list of JSON maps to Fantom types.
  private [Str:Obj][] fromList(Str:Obj json)
  {
    items := (Obj[])json["items"]
    return items.map |v| { fromMap(v) }
  }

  ** Convert JSON map to Fantom types.
  private Str:Obj fromMap(Str:Obj json)
  {
    json.map |val, key|
    {
      DateTime.fromHttpStr(val as Str ?: "", false) ?: val
    }
  }

  private const Uri apiBase
  private const Uri apiSend
  private const Uri apiLog
  private const Uri apiUnsubscribes
}
