# Mailgun

Fantom wrapper for [Mailgun](https://http://www.mailgun.com) email service.

## Usage

    mailgun := Mailgun
    {
      it.apiKey = "key-3ax6xnjp29jd6fds4gc373sgvjxteol0"
      it.domain = "samples.mailgun.org"
    }

    mailgun.send([
      "from": "me@samples.mailgun.org",
      "to": "alex@mailgun.net, ev@mailgun.net",
      "subject": "Hey There!",
      "text": "Hi :)"
    ])
