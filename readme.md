# Mailgun

Fantom wrapper for [Mailgun](http://www.mailgun.com) email service.

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


## Install

    fanr install -r http://eggbox.fantomfactory.org/fanr/ mailgun

## Documentation

Full Usage documentation:

[http://eggbox.fantomfactory.org/pods/mailgun/doc/](http://eggbox.fantomfactory.org/pods/mailgun/doc/)

Full API documentation:

[http://eggbox.fantomfactory.org/pods/mailgun/api/](http://eggbox.fantomfactory.org/pods/mailgun/api/)
