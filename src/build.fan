#! /usr/bin/env fan
//
// Copyright (c) 2013, Andy Frank
// Licensed under the MIT License
//
// History:
//   12 Apr 2013  Andy Frank  Creation
//

using build

**
** Build: mailgun
**
class Build : BuildPod
{
  new make()
  {
    podName = "mailgun"
    summary = "Mailgun"
    version = Version("1.0.2")
    meta = ["vcs.uri" : "https://bitbucket.org/afrankvt/mailgun/",
            "license.name": "MIT",
            "repo.public": "true"]
    depends = ["sys 1.0",
               "util 1.0",
               "concurrent 1.0",
               "web 1.0",
               "util 1.0",
               "email 1.0"]
    srcDirs = [`fan/`]
  }
}