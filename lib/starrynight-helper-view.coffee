{View, $} = require 'atom-space-pen-views'
{BufferedProcess} = require 'atom'
fs = require 'fs'
path = require 'path'
velocity = require 'velocity-animate/velocity'

PANE_TITLE_HEIGHT_CLOSE = 26
PANE_TITLE_HEIGHT_OPEN = 150

module.exports =

# Public: Main Starrynight's view that extends the View prototype.
class starryNightHelperView extends View

  # Starrynight's process
  @process: null

  # Public: Build the pane
  #
  # Returns: main's pane widget
  @content: ->
    @div click: 'onClick', style: 'display: inline-block !important; height: 100% !important; overflow: scroll; width: 500px; white-space: nowrap; text-overflow:  clip;', class: 'starrynight-helper
      tool-panel panel-bottom text-smaller', =>
      @div class: 'panel-heading status-bar tool-panel', =>
        @div class: 'status-bar-left pull-left starrynight-logo'
        @div outlet: 'starrynightStatus', class: 'status-bar-right pull-right', =>
          @span class: 'loading loading-spinner-tiny inline-block'
      @div class: 'panel-body', =>
        @div outlet: 'starrynightDetails', class: 'starrynight-details'

  # Public: Initialize the current package
  #
  # serializeState - The [description] as {[type]}.
  #
  # Returns: `undefined`
  initialize: (serializeState) ->
    # Import Velocity into the main window's context
    @velocity = velocity.bind @
    # Pane is closed by default
    @isPaneOpened = false
    # Current pane status
    @paneIconStatus = null
    # Register toggle and reset
    atom.commands.add 'atom-workspace',
      'starrynight-helper:reset': => @reset()
      'starrynight-helper:toggle': => @toggle()
      'starrynight-helper:showHide': => @showHide()
      'starrynight-helper:help': => @help()
      'starrynight-helper:environment': => @environment()
      'starrynight-helper:nightwatch': => @nightwatch()
      'starrynight-helper:autoconfig': => @autoconfig()
    # Ensure destruction of Starrynight's process
    $(window).on 'beforeunload', => @_killStarrynight()

  # Public: Returns an object that can be retrieved when package is activated
  #
  # Returns: `undefined`
  serialize: ->

  # Public: On click, make the pane appearing or disappearing.
  #
  # evt - The event as EventType.
  #
  # Returns: `undefined`
  onClick: (evt) => @showHide()

  # Public: Make the pane appearing or disappearing.
  #
  # Returns: `undefined`
  showHide: =>
    @isPaneOpened = not @isPaneOpened
    height = if @isPaneOpened then PANE_TITLE_HEIGHT_OPEN \
      else PANE_TITLE_HEIGHT_CLOSE
    @velocity
      properties:
        height: height
      options:
        duration: 100

  # Private: Kill Starrynight's process and its subprocess (Mongo).
  #
  # Returns the [Description] as `undefined`.
  _killStarrynight: ->
    # Kill Starrynight's process if it's running
    @process?.kill()
    # Only kill Mongo if it's Starrynight's default one
    return unless @mongoURL is ''
    # Sometimes Mongo get stuck, force exit it
    new BufferedProcess
      command: 'killall'
      args: ['mongod']

  # Public static: Format a Starrynight log.
  #
  # str - The log to check and format, if necessary.
  #
  # Returns Either a raw string or a formated Starrynight log in HTML.
  @LogFormat = (str) ->
    # Remove ANSI colors
    raw = str.replace /\033\[[0-9;]*m/g, ''
    # Check if it's common message or a Starrynight log
    pattern = ///
      ^([I,W])                    # Only take I or W
      \d{8}-                      # Remove the date
      (\d{2}:\d{2}:\d{2}.\d{3})   # Get the time
      \(\d\)\?\s(.*)              # Get the reason
    ///
    found = (raw.match pattern)?[1..3]
    return raw unless found
    # Format the Starrynight log
    css_class = if found[0] is 'I' then 'text-info' else 'text-error'
    "<p><span class='#{css_class}'>#{found[1]}</span> #{found[2]}</p>"

  # Private: Display default pane.
  #
  # Returns: `undefined`
  _displayPane: ->
    # Set an initial message before appending the panel
    @paneIconStatus = 'WAITING'
    @setMsg 'Launching StarryNight...'
    # Clear height if it has been modified formerly
    @height PANE_TITLE_HEIGHT_CLOSE

    @isPaneOpened = false
    # Fade the panel in
    @velocity 'fadeIn', duration: 100, display: 'block'
    # Add the view to the current workspace
    atom.workspace.addRightPanel item: @

  # Private: Get and check settings.
  # Throws Error in case of wrong settings.
  # Returns: `undefined`
  _getSettings: ->
    # Get the configured Starrynight's path, port and production flag
    @starrynightAppPath = atom.config.get 'starrynight-helper.starrynightAppPath'
    @starrynightPath = atom.config.get 'starrynight-helper.starrynightPath'
    @starrynightPort = atom.config.get 'starrynight-helper.starrynightPort'
    @isStarrynightProd = atom.config.get 'starrynight-helper.production'
    @isStarrynightDebug = atom.config.get 'starrynight-helper.debug'
    @mongoURL = atom.config.get 'starrynight-helper.mongoURL'
    @settingsPath = atom.config.get 'starrynight-helper.settingsPath'
    # Check if the command is installed on the system
    isCliDefined = fs.existsSync @starrynightPath
    # Set an error message if Starrynight CLI cannot be found
    unless isCliDefined
      throw new Error "<h3>Starrynight command not found: #{@starrynightPath}</h3>
        <p>You can override these settings in this package preference or in a custom mup.json file.</p>"

    # Check for project specific settings
    mup_project_path = path.join atom.project.getPaths()[0], 'mup.json'
    isMupPrjCreated = fs.existsSync mup_project_path

    # Only overwrite settings if a `mup.json` is available
    if isMupPrjCreated
      try
        # @TODO Create better parsing stance
        cnt = fs.readFileSync mup_project_path
        mup = JSON.parse cnt
        # Overwrite app path if it exists
        @starrynightAppPath = mup.app if mup.app?
      catch err
        @paneIconStatus = 'WARNING'
        @setMsg "<h3>mup.json is corrupted: #{err}.
          Default back to current settings.</h3>"

    # Check if the current project owns a Starrynight project
    starrynight_project_path = path.join atom.project.getPaths()[0], @starrynightAppPath, '.meteor/nightwatch.json'
    isPrjCreated = fs.existsSync starrynight_project_path

    # Set an error message if no Starrynight project is found
    unless isPrjCreated
      throw new Error "<h3>No Starrynight project found in:</h3><br />#{starrynight_project_path}"

    # check if settings path exists
    _settingsPath =
      if @settingsPath[0] is '/'
        @settingsPath
      else
        path.join atom.project.getPaths()[0], @settingsPath
    isSettingsPathValid = fs.existsSync _settingsPath
    # Set an error if settings path is invalid
    unless isSettingsPathValid
      throw new Error "
        <h3>Unable to locate settings JSON file at: #{@settingsPath}</h3><br>
        <p>Please make sure the file exists, or remove it from settings.</p>"

  # Private: Modify process env and parse mup projects.
  #
  # Returns: `undefined`
  _modifyProcessEnv: ->
    # Tweek process path to circumvent Starrynightite issue:
    # https://github.com/oortcloud/starrynightite/issues/203
    process.env.PATH = "#{process.env.HOME}/.starrynight/tools/" +
      "latest/bin:#{process.env.PATH}"
    # Check if Starrynight should use a custom MongoDB
    if @mongoURL isnt ''
      # Set MongoDB's URL
      process.env.MONGO_URL = @mongoURL
    else
      # Unset former uses
      delete process.env.MONGO_URL if process.env.MONGO_URL?
    if @mongoOplogURL isnt ''
      # Set MongoDB's URL
      process.env.MONGO_OPLOG_URL = @mongoOplogURL
    else
      # Unset former uses
      delete process.env.MONGO_OPLOG_URL if process.env.MONGO_OPLOG_URL?
    # Check if a specific project file is available which could
    #  overwrite settings variables
    mup_project_path = path.join atom.project.getPaths()[0], 'mup.json'
    isMupPrjCreated = fs.existsSync mup_project_path
    # Only overwrite settings if a `mup.json` is available
    if isMupPrjCreated
      try
        cnt = fs.readFileSync mup_project_path
        mup = JSON.parse cnt
        process.env.MONGO_URL = mup.env.MONGO_URL if mup.env?.MONGO_URL?
        process.env.MONGO_OPLOG_URL = mup.env.MONGO_OPLOG_URL \
          if mup.env?.MONGO_OPLOG_URL?
        @starrynightPort = mup.env.PORT if mup.env?.PORT?
      catch err
        @paneIconStatus = 'WARNING'
        @setMsg "<h3>mup.json is corrupted: #{err}.
          Default back to current settings.</h3>"




  # Public: Reset Starrynight state and Mongo DB.
  #
  # Returns: `undefined`
  environment: =>
    @setMsg 'Environment!'
    @paneIconStatus = 'INFO'

    unless @hasParent()
      # Display main pane
      @_displayPane()
    try
      # Get and set settings
      # @_getSettings()
      # Modify process env and check mup files
      # @_modifyProcessEnv()
      @setMsg 'Trying to starrynight display-env'
      # Launch Starrynight reset
      new BufferedProcess
        command: 'starrynight'
        args: ['display-env']
        options:
          cwd: path.join atom.project.getPaths()[0], @starrynightAppPath
          env: process.env
        stdout: @paneAddInfo
        stderr: @paneAddErr
        #exit: @paneAddExit
      @setMsg 'Finished?'
    catch err
      @paneIconStatus = 'ERROR'
      @setMsg err.message



  # Public: starrynight run-tests --framework nightwatch
  #
  # Returns: list of commands
  autoconfig: =>
    @setMsg 'Autoconfig'
    @paneIconStatus = 'INFO'

    unless @hasParent()
      # Display main pane
      @_displayPane()
    try
      # Get and set settings
      # @_getSettings()
      # Modify process env and check mup files
      # @_modifyProcessEnv()
      @setMsg 'Trying to run Nightwatch...'
      # Launch Starrynight reset
      new BufferedProcess
        command: 'starrynight'
        args: ['generate', '--autoconfig']
        #options:
        #  cwd: path.join atom.project.getPaths()[0], @starrynightAppPath
        #  env: process.env
        stdout: @paneAddInfo
        stderr: @paneAddErr
        #exit: @paneAddExit
      @setMsg '--Nightwatch--'
    catch err
      @paneIconStatus = 'ERROR'
      @setMsg err.message


  # Public: starrynight run-tests --framework nightwatch
  #
  # Returns: list of commands
  nightwatch: =>
    @setMsg 'Nightwatch'
    @paneIconStatus = 'INFO'

    unless @hasParent()
      # Display main pane
      @_displayPane()
    try
      # Get and set settings
      # @_getSettings()
      # Modify process env and check mup files
      # @_modifyProcessEnv()
      @setMsg 'Trying to run Nightwatch...'
      # Launch Starrynight reset
      new BufferedProcess
        command: 'starrynight'
        args: ['run-tests', '--framework', 'nightwatch']
        options:
          cwd: path.join atom.project.getPaths()[0], @starrynightAppPath
          env: process.env
        stdout: @paneAddInfo
        stderr: @paneAddErr
        #exit: @paneAddExit
      @setMsg '--Nightwatch--'
    catch err
      @paneIconStatus = 'ERROR'
      @setMsg err.message


  # Public: starrynight --help
  #
  # Returns: list of commands
  help: =>
    @setMsg 'StarryNight'
    @paneIconStatus = 'INFO'

    unless @hasParent()
      # Display main pane
      @_displayPane()
    try
      # Get and set settings
      # @_getSettings()
      # Modify process env and check mup files
      # @_modifyProcessEnv()
      @setMsg 'Trying to run StarryNight...'
      # Launch Starrynight reset
      new BufferedProcess
        #command: 'starrynight'
        #args: ['--help']
        command: 'ls'
        args: ['-la']
        options:
          cwd: path.join atom.project.getPaths()[0], @starrynightAppPath
          env: process.env
        stdout: @paneAddInfo
        stderr: @paneAddErr
        #exit: @paneAddExit
      @setMsg '--STARRYNIGHT--'
    catch err
      @paneIconStatus = 'ERROR'
      @setMsg err.message

# Public: Launch or kill the pane and the
  # Public: Reset Starrynight state and Mongo DB.
  #
  # Returns: `undefined`
  reset: =>
    # Check if Starrynight is launched
    unless @hasParent()
      # Display main pane
      @_displayPane()
    try
      # Get and set settings
      @_getSettings()
      # Modify process env and check mup files
      @_modifyProcessEnv()
      @setMsg 'Project reset.'
      # Launch Starrynight reset
      new BufferedProcess
        command: @starrynightPath
        args: ['reset']
        options:
          cwd: path.join atom.project.getPaths()[0], @starrynightAppPath
          env: process.env
      @setMsg 'Project reset.'
    catch err
      @paneIconStatus = 'ERROR'
      @setMsg err.message

  # Public: Launch or kill the pane and the Starrynight process.
  #
  # Returns: `undefined`
  toggle: =>
    # Check if Starrynight is launched
    if @hasParent()
      # Fade out the pane before destroying it
      @velocity 'fadeOut', duration: 100
      setTimeout =>
        # Detach pane from the editor's view
        @detach()
        # Kill former process
        @_killStarrynight()
      , 100
      return
    # Display main pane
    @_displayPane()
    # Store args
    args = []
    try
      # Get and check settings
      @_getSettings()
      # Modify process env and check mup files
      @_modifyProcessEnv()
      # Check if the production flag needs to be added
      args.push '--production' if @isStarrynightProd
      # Check if Starrynight is in debug mode
      args.push 'debug' if @isStarrynightDebug
      # Check if Starrynight's port need to be configure
      args.push '--port', String @starrynightPort if @starrynightPort
      # Check if settings file should be configured
      args.push '--settings', String @settingsPath if @settingsPath
      # Launch Starrynight
      @process = new BufferedProcess
        command: @starrynightPath
        args: args
        options:
          cwd: path.join atom.project.getPaths()[0], @starrynightAppPath
          env: process.env
        stdout: @paneAddInfo
        stderr: @paneAddErr
        exit: @paneAddExit
    catch err
      @paneIconStatus = 'ERROR'
      @setMsg err.message

  # Public: Force appearing of the pane
  #
  # Returns: `undefined`
  forceAppear: =>
    @isPaneOpened = true
    @velocity
      properties: height: PANE_TITLE_HEIGHT_OPEN
      options: duration: 100

  # Public: Set message in pane's details section
  #
  # msg         - The message as String.
  # isAppended  - A flag for appending or replacing as Boolean.
  #
  # Returns: `undefined`
  setMsg: (msg, isAppended = false) =>
    switch @paneIconStatus
      when 'INFO'
        @starrynightStatus.html '<span class="icon-check text-success"></span>'
      when 'WAITING'
        @starrynightStatus.html '<span class="icon-gear text-highlight faa-spin animated"></span>'
      else
        @starrynightStatus.html '<span class="icon-help faa-flash animated text-warning"></span>'
        # When an error is detected, force appearance of the pane
        @forceAppear()
    if isAppended
      @starrynightDetails.append msg
    else
      @starrynightDetails.html msg
    # Ensure scrolling
    @starrynightDetails.parent().scrollToBottom()

  # Patterns used for OK status on Starrynight CLI's output
  PATTERN_METEOR_OK: ///
    App.running.at:         # Classic start of Starrynight
    | remove.dep            # Removal of dependencies in Famono
    | Scan.the.folder       # End of requirements in Famono
    | Ensure.dependencies   # Generally after having fixed an error
    | server.restarted      # Fresh code on Starrynight's server
    | restarting            # Sometimes Starrynight do use this one
  ///

  # Patterns used for error status on Starrynight CLI's output
  PATTERN_METEOR_ERROR: ///
    [E|e]rror               # Basic error
    | STDERR                # Received a console.error
    | is.crashing           # Server crashing
    | Exited.with.code      # Another case of server crashing
  ///

  # Pattenrs used for detecting unworthy status changes
  # (like a simple console.log in the Starrynight app)
  PATTERN_METEOR_UNCHANGED: ///
    I[0-9]                  # console.log statements starts with I and a date
  ///

  # Public: Add info in the pane and determine which type of info to add.
  #
  # outputs - The Starrynight's CLI outputs as String.
  #
  # Returns: `undefined`
  paneAddInfo: (outputs) =>
    # Iterate over each new non blank lines
    # and weird white space extensions in the outputs
    tOuputs = outputs.split /\n|\ {8,}/
    for output in tOuputs when output isnt ''
      # spare former status
      oldstatus = @paneIconStatus
      # Check for OK patterns
      @paneIconStatus = if output.match @PATTERN_METEOR_OK then 'INFO'
      # Check for error patterns
      else if output.match @PATTERN_METEOR_ERROR then 'ERROR'
      else if output.match @PATTERN_METEOR_UNCHANGED then oldstatus
      else 'WAITING'
      # Display the message with the appropriare status
      msg = "<p>#{starryNightHelperView.LogFormat output}</p>"
      @setMsg msg, true

  # Public: Add error in the pane
  #
  # output - The Starrynight's output as String.
  #
  # Returns: `undefined`
  paneAddErr: (output) =>
    msg = "<p class='text-error'>#{starryNightHelperView.LogFormat output}</p>"
    @paneIconStatus = 'ERROR'
    @setMsg msg, true

  # Public: Add exit status in the pane.
  #
  # code - The Starrynight's exit code as Integer.
  #
  # Returns: `undefined`
  paneAddExit: (code) =>
    # Nullify current process
    @process.kill()
    @process = null
    # Display the exit status
    msg = "<p class='text-error'>Starrynight has exited with
      status code: #{code}</p>"
    @paneIconStatus = 'ERROR'
    @setMsg msg, true
