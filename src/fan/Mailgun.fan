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
    attach := File[,]

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
      else if (p is FilePart)
      {
        fp := (FilePart)p
        attach.add(fp.file)
      }
    }
    if (!attach.isEmpty) params["attachment"] = attach

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
// Events
//////////////////////////////////////////////////////////////////////////

  **
  ** Get events for this Mailgun account.
  **
  **  - filters: The set of filters to apply for retrieving events, or null
  **    for Mailgun default.
  **  - begin: a 'Date' or 'DateTime' to start the filter from, or null for
  **    Mailgun default.
  **  - end: a 'Date' or 'DateTime' to filter up to, or null for Mailgun default.
  **  - limit: Max number of items to return, or null for Mailgun default.
  **
  ** See Mailgun documentation for events:
  **
  ** `https://documentation.mailgun.com/en/latest/api-events.html`
  **
  [Str:Obj][] events([Str:Str]? filters := null, Obj? begin := null, Obj? end := null, Int? limit := null)
  {
    params := Str:Str[:] {
      if (begin != null)  it["begin"] = rfc2822(begin)
      if (end != null)    it["end"] = rfc2822(end)
      if (limit != null)  it["limit"] = limit.toStr
    }
    filters?.each |v, k| { params[k] = v }
    return invoke("GET", apiEvents, params)
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
  @Deprecated { msg = "Use the events api instead" }
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
// Paging
//////////////////////////////////////////////////////////////////////////

  ** Get the first page items. See `invoke` for details.
  [Str:Obj][] pageFirst(Str:Obj item)
  {
    uri := item["_paging"]?->get("first")
    return uri == null ? [,] : invoke("GET", uri)
  }

  ** Get the next page of items. See `invoke` for details.
  [Str:Obj][] pageNext(Str:Obj item)
  {
    uri := item["_paging"]?->get("next")
    return uri == null ? [,] : invoke("GET", uri)
  }

  ** Get the previous page of items. See `invoke` for details.
  [Str:Obj][] pagePrev(Str:Obj item)
  {
    uri := item["_paging"]?->get("previous")
    return uri == null ? [,] : invoke("GET", uri)
  }

  ** Get the last page items. See `invoke` for details.
  [Str:Obj][] pageLast(Str:Obj item)
  {
    uri := item["_paging"]?->get("last")
    return uri == null ? [,] : invoke("GET", uri)
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
  ** API calls that return a list of items will include paging
  ** information in the first and last item. You can pass those items
  ** to the various paging methods to retrieve more items.
  **
  Obj invoke(Str method, Uri endpoint, [Str:Obj]? params := null)
  {
    WebClient? c
    try
    {
      if (!endpoint.isPathAbs) throw ArgErr("Invalid URI: $endpoint")

      // Configure for public/private api.
      dom := domain
      key := privApiKey
      if (isPubEndpoint(endpoint))
      {
        // Public API must not use domain
        dom = "."
        key = pubApiKey
      }

      uri := endpoint.isAbs ? endpoint : `${apiBase}${dom}${endpoint}`
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
          if (params.containsKey("attachment")) postMultiPart(c, params)
          else c.postForm(params)
          res = parseJson(c.resStr)

        default:
          throw ArgErr("Unsupported method $method")
      }

      // check response
      if (c.resCode != 200) throw Err(res["message"] ?: "")

      // return results
      if (res.containsKey("items"))
      {
        [Str:Obj][] items := ((Obj[])res["items"]).map |v| { toMap(v) }
        // add paging info
        if (!items.isEmpty && res.containsKey("paging"))
        {
          // swizzle key to protect against key collision since we have
          // to inject the paging information into the first and last items
          paging := ((Map)res["paging"]).map |v| { Uri.fromStr(v) }
          items.first["_paging"] = paging
          items.last["_paging"]  = paging
        }
        return items
      }
      else return toMap(res)
    }
    finally c?.close
  }

  ** Post attachements using multipart/form-data
  private Void postMultiPart(WebClient c, [Str:Obj] params)
  {
    boundary := "FanMailgun${Random.makeSeeded().nextBuf(8).toHex}"
    c.reqMethod = "POST"
    c.reqHeaders["Content-Type"] = "multipart/form-data; boundary=${boundary}"
    c.writeReq
    params.each |val, param|
    {
      c.reqOut.print("--${boundary}").print(CRLF)
      if (val is List)
      {
        files := (File[])val
        files.each |f| { writePart(c.reqOut, param, f) }
      }
      else writePart(c.reqOut, param, val)
    }
    c.reqOut.print("--${boundary}--").print(CRLF).flush.close
    c.readRes
  }

  ** Utility to write a single part of multipart/form-data
  private static Void writePart(OutStream out, Str name, Obj val)
  {
    h  := [Str:Str][:]
    cd := "form-data; name=${name.toCode}"
    if (val is File)
    {
      f := (File)val
      cd = "$cd; filename=${f.name.toCode}"
      h["Content-Type"] = f.mimeType.toStr
      h["Content-Transfer-Encoding"] = "base64"
      in := f.in
      try
      {
        b64 := Buf()
        FilePart.encodeBase64(in, f.size, b64.out)
        val = b64.flip.readAllStr
      }
      finally
        in.close
    }
    h["Content-Disposition"] = cd
    WebUtil.writeHeaders(out, h)
    out.print(CRLF)
    out.print(val.toStr).print(CRLF)
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

  ** Get the RFC-2822 encoding of a timestamp. Obj may be a Date (assumed midnight)
  ** or a DateTime. If null, the get the encoding for [now]`DateTime.now`
  private Str rfc2822(Obj? obj)
  {
    ts := DateTime.now
    if (obj is Date) ts = ((Date)obj).midnight
    else if (obj is DateTime) ts = (DateTime)ts
    else if (obj != null) throw ArgErr("Cannot encode ${obj}: ($obj.typeof)")
    return ts.toLocale("WWW, D MMM YYYY hh:mm:ss zzz", Locale.en)
  }

  private static const Str CRLF     := "\r\n"
  private const Uri apiBase         := `https://api.mailgun.net/v3/`
  private const Uri apiSend         := `/messages`
  private const Uri apiEvents       := `/events`
  private const Uri apiLog          := `/log`
  private const Uri apiUnsubscribes := `/unsubscribes`
  private const Uri apiComplaints   := `/complaints`
  private const Uri apiBounces      := `/bounces`
  private const Uri apiStats        := `/stats`
  private const Uri apiTags         := `/tags`
  private const Uri apiAddress      := `/address`
}
