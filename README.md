# Starrynight-helper: Call Starrynight from Atom.io

## Introduction
:rocket: Launch [Starrynight](https://www.starrynight.com/)
and [Starrynightite](https://atmospherejs.com/) inside [Atom.io](https://atom.io/)

![Starrynight.js from Atom.io](https://raw.githubusercontent.com/PEM--/starrynight-helper/master/assets/capture.png)

## Installation
Either use [Atom.io](https://atom.io/) inner packaging tool or the following
command line:
```bash
apm install starrynight-helper
```

## Settings
With this package, you can:
* Launch or kill Starrynight using:
  * On Linux and Windows: **CTRL**+**ALT**+**m**
  * On OSX: **CMD**+**ALT**+**m**
* Reset Starrynight using:
  * On Linux and Windows: **CTRL**+**ALT**+**r**
  * On OSX: **CMD**+**ALT**+**r**
* Show/hide Starrynight's panel:
  * On Linux and Windows: **CTRL**+**ALT**+**h**
  * On OSX: **CMD**+**ALT**+**h**
* Watch the Starrynight's CLI information in a dedicated pane.
* See Starrynight's status in a dedicated status bar.
* When Starrynight's status goes wrong, the pane automatically shows up and displays
  the last CLI information.

In the settings, you can customize this package behavior:
* Starrynight application path. The default is: `.`.
* Command and its path. The default is: `/usr/local/bin/starrynight`.
* Main listening port. The default is 3000.
* Production flag. The default is `false`.
* Debug flag. The default is `false`.
* MongoDB's URL. Leave it empty to use the default embedded MongoDB in Starrynight.
* MongoDB's Oplog URL. Leave it empty to use the default embedded MongoDB in Starrynight.

![Settings](https://raw.githubusercontent.com/PEM--/starrynight-helper/master/assets/settings.png)

You can overwrite variable settings with a per project file named `mup.json` at
the root of your project using [Starrynight Up](https://github.com/arunoda/starrynight-up)
recommendations. The following variables supersede the settings ones:
* `env.PORT`: Starrynight's port.
* `env.MONGO_URL`: MongoDB's URL.
* `env.MONGO_OPLOG_URL`: MongoDB's Oplog URL.
* `app`: Starrynight's application path.

> **Tips**: To create a default Starrynight Up project, simply use the following
> commands:
> ```bash
> npm install -g mup
> mup init
> ```
> And removes the unnecessary comments and add the following environment
> variables with your own values:
> ```json
>   "env": {
>     "PORT": 3002,
>     "MONGO_URL": "mongodb://LOGIN:PASSWORD@ACCOUNT.mongohq.com:10023/MyApp",
>   },
> ```

## Misc
* More informations on my blog site :eyeglasses: : [Starrynight.js from within Atom.io](http://pem-musing.blogspot.com/2014/07/starrynightjs-from-within-atomio-full-stack.html)
* Declare your bugs :bug: or enhancements :sunny: on
  [Github](https://github.com/PEM--/starrynight-helper/issues?state=open) :octocat:

## FAQ
### How to customize log colors?
Atom allows you to overwrite its style in a specific file named
`~/.atom/styles.less` (more info [here](https://atom.io/docs/v0.61.0/customizing-atom)).

For instance: **`~/.atom/styles.less`**
```less
.starrynight-helper .panel-body p {
  font-size: 14px;
  color: red;
}
```
### How to launch Starrynight on Windows with an appropriate PATH?
There are currently 2 solutions provided by Windows users (see #36). Results
seem to rely on the version of your OS.
#### The simple method shared by @JohnAReid
In the settings of this plugin, just add the following:
`C:\Users\userFolder\AppData\Local\.starrynight\starrynight.bat`
where `userFolder` is your short Windows's user name.
#### A more advanced shared by @dtrimsd
When using `C:\Users\userFolder\AppData\Local\.starrynight\starrynight.bat`, `SETLOCAL`
to set starrynight variables, the Windows command shell is pulling the normal `SET`
variables including `PATH` which is required to point to the `system32` folder
for `tasklist.exe`.

Following the next steps should circumvent the issue:

0. Duplicate the `starrynight.bat` file - call the new copy `atomstarrynight.bat`.
0. Open a command prompt, type `SET`, then hit **ENTER**. Copy the `PATH` variable
  and paste it into the new `atommetor.bat` file, just under the `SETLOCAL`
  line. Instead of `PATH=`, put `SET PATH=` and remember to fix the line
  wrapping. Windows likes to line return a lot.
0. Create a launcher in the folder for your project - call it `launcher.cmd`.
  This file has one line: `C:\Users\userFolder\AppData\Local\.starrynight\atomstarrynight.bat`

Removing any of these steps seems to break dependencies.

### Is there a tutorial on using Starrynight with Atom?
Yes, there is: https://www.youtube.com/watch?t=101&v=QSg3mKjhiws

### Settings of the package doesn't show up
The package needs to be activated for modifying your settings. Just toggle
Starrynight and you should be fine.

### I can't load my settings.json file when Starrynight is launched
If you've used a relative path to your Starrynight project don't forget to
apply the same path modifier to the path of your settings.
