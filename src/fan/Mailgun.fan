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
  }

  ** Private API key for your Mailgun account.
  const Str privApiKey

  ** Public API key for your Mailgun account.
  const Str? pubApiKey

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
    invoke("GET", apiUnsubscribes, Str:Str[:] {
      if (limit != null) it["limit"] = limit.toStr
      if (skip  != null) it["skip"] = skip.toStr
    })
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
// Spam Complaints
//////////////////////////////////////////////////////////////////////////

  **
  ** Get list of spam complaints.
  **  - limit: Max number of records to return, or null for Mailgun default
  **  - skip:  Number of records to skip, or null for Mailgun default
  **
  ** See Mailgun documentation for complaints:
  **
  ** `http://documentation.mailgun.net/api-complaints.html`
  **
  [Str:Obj][] complaints(Int? limit := null, Int? skip := null)
  {
    invoke("GET", apiComplaints, Str:Str[:] {
      if (limit != null) it["limit"] = limit.toStr
      if (skip  != null) it["skip"] = skip.toStr
    })
  }

  **
  ** Get a single spam complaint by email address. Returns response from
  ** Mailgun if successful. Throws Err if fails for any reason.
  **
  ** See Mailgun documentation for complaints:
  **
  ** `http://documentation.mailgun.net/api-complaints.html`
  **
  Str:Obj getComplaint(Str address)
  {
    invoke("GET", `$apiComplaints/$address`)
  }

  **
  ** Adds an address to complaints table. Returns response from Mailgun
  ** if successful. Throws Err if fails for any reason.
  **
  ** See Mailgun documentation for complaints:
  **
  ** `http://documentation.mailgun.net/api-complaints.html`
  **
  Str:Obj addComplaint(Str address)
  {
    invoke("POST", apiComplaints, ["address":address])
  }

  **
  ** Remove a given spam complaint. Returns response from Mailgun if
  ** successful. Throws Err if fails for any reason.
  **
  ** See Mailgun documentation for complaints:
  **
  ** `http://documentation.mailgun.net/api-complaints.html`
  **
  Str:Obj removeComplaint(Str addressOrId)
  {
    invoke("DELETE", `$apiComplaints/$addressOrId`)
  }

//////////////////////////////////////////////////////////////////////////
// Bounces
//////////////////////////////////////////////////////////////////////////

  **
  ** Get list of bounces.
  **  - limit: Max number of records to return, or null for Mailgun default
  **  - skip:  Number of records to skip, or null for Mailgun default
  **
  ** See Mailgun documentation for bounces:
  **
  ** `http://documentation.mailgun.net/api-bounces.html`
  **
  [Str:Obj][] bounces(Int? limit := null, Int? skip := null)
  {
    invoke("GET", apiBounces, Str:Str[:] {
      if (limit != null) it["limit"] = limit.toStr
      if (skip  != null) it["skip"] = skip.toStr
    })
  }

  **
  ** Get a single bounce event by email address. Returns response from
  ** Mailgun if successful. Throws Err if fails for any reason.
  **
  ** See Mailgun documentation for bounces:
  **
  ** `http://documentation.mailgun.net/api-bounces.html`
  **
  Str:Obj getBounce(Str address)
  {
    invoke("GET", `$apiBounces/$address`)
  }

  **
  ** Adds a permanent bounce to bounce table. Updates existing recored
  ** if already there. Returns response from Mailgun if successful.
  ** Throws Err if fails for any reason.
  **
  ** See Mailgun documentation for bounces:
  **
  ** `http://documentation.mailgun.net/api-bounces.html`
  **
  Str:Obj addBounce(Str address, Int? errCode := null, Str? errMsg := null)
  {
    invoke("POST", apiBounces, Str:Str["address":address] {
      if (errCode != null) it["code"] = errCode.toStr
      if (errMsg  != null) it["error"] = errMsg.toStr
    })
  }

  **
  ** Remove a bounce event.  Returns response from Mailgun if
  ** successful. Throws Err if fails for any reason.
  **
  ** See Mailgun documentation for bounces:
  **
  ** `http://documentation.mailgun.net/api-bounces.html`
  **
  Str:Obj removeBounce(Str addressOrId)
  {
    invoke("DELETE", `$apiBounces/$addressOrId`)
  }

//////////////////////////////////////////////////////////////////////////
// Stats
//////////////////////////////////////////////////////////////////////////

  **
  ** Get list of event stat items.  Each record counts for one
  ** event per one day. Throws Err if fails for any reason.
  **
  ** Available event names:
  **  - sent
  **  - delivered
  **  - bounced
  **  - dropped
  **  - complained
  **  - unsubscribed
  **  - opened
  **  - clicked
  **
  ** See Mailgun documentation for stats:
  **
  ** `http://documentation.mailgun.net/api-bounces.html`
  **
  [Str:Obj][] stats(Str event, Date? start := null, Int? limit := null, Int? skip := null)
  {
    invoke("GET", apiStats, Str:Str["event":event] {
      if (start != null) it["start-date"] = start.toLocale("YYYY-MM-DD")
      if (limit != null) it["limit"] = limit.toStr
      if (skip  != null) it["skip"] = skip.toStr
    })
  }

  **
  ** Deletes all counters for given tag.  Returns response from
  ** Mailgun.  Throws Err if fails for any reason.
  **
  ** See Mailgun documentation for stats:
  **
  ** `http://documentation.mailgun.net/api-bounces.html`
  **
  Str:Obj removeTag(Str tag)
  {
    invoke("DELETE", `$apiTags/$tag`)
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
    invoke("GET", apiLog, Str:Str[:] {
      if (limit != null) it["limit"] = limit.toStr
      if (skip  != null) it["skip"] = skip.toStr
    })
  }

//////////////////////////////////////////////////////////////////////////
// Address
//////////////////////////////////////////////////////////////////////////

  ** Convenience to determine if an email address is valid or not
  Bool isValidAddress(Str address)
  {
    validateAddress(address)["is_valid"]
  }

  ** Validate the email address using Mailgun's email validation service
  [Str:Obj?] validateAddress(Str address)
  {
    if (pubApiKey == null) throw ArgErr("Must configure public api key to validate")
    res := invoke("GET", `$apiAddress/validate`, ["address": address])
    return res
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  **
  ** Invoke a REST API with given arguments. If method is "GET"
  ** params sent in query string, otherse as request body.
  **
  **    invoke("GET", `/log`, ["limit":"25"])
  **
  Obj invoke(Str method, Uri endpoint, [Str:Str]? params := null)
  {
    WebClient? c
    try
    {
      if (!endpoint.isRel && !endpoint.isPathAbs) throw ArgErr("Invalid URI: $endpoint")

      // Configure for public/private api.
      dom := domain
      key := privApiKey
      if (isPubEndpoint(endpoint))
      {
        // Public API must not use domain
        dom = "."
        key = pubApiKey
      }

      uri := `${apiBase}${dom}${endpoint}`
      if (method == "GET" && params != null) uri = uri.plusQuery(params)

      // init client
      c = WebClient(uri)
      c.reqHeaders["Authorization"] = "Basic " + "api:$key".toBuf.toBase64

      // send/rec
      [Str:Obj]? res
      switch (method)
      {
        case "GET":     // fall
        case "DELETE":
          c.reqMethod = method
          c.writeReq
          c.readRes
          res = parseJson(c.resStr)

        case "POST":
          c.postForm(params); res=parseJson(c.resStr)

        default:
          throw ArgErr("Unsupported method $method")
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
  private Str:Obj? toMap(Str:Obj? json)
  {
    return json.map |v->Obj?| { DateTime.fromHttpStr(v as Str ?: "", false) ?: v }
  }

  ** Is the endpoint for the public API?
  private Bool isPubEndpoint(Uri endpoint)
  {
    endpoint.pathStr.startsWith("$apiAddress")
  }

  private const Uri apiBase         := `https://api.mailgun.net/v3/`
  private const Uri apiSend         := `/messages`
  private const Uri apiLog          := `/log`
  private const Uri apiUnsubscribes := `/unsubscribes`
  private const Uri apiComplaints   := `/complaints`
  private const Uri apiBounces      := `/bounces`
  private const Uri apiStats        := `/stats`
  private const Uri apiTags         := `/tags`
  private const Uri apiAddress      := `/address`
}
