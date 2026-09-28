--game

    --shared game thingies
    sharedBackground = require("objects.game.shared.sharedBackground")
    vertSprite = require("objects.game.shared.vertSprite")

    --mania
    maniaLane = require("objects.game.mania.maniaLane")
    maniaNote = require("objects.game.mania.maniaNote")
    maniaPlayField = require("objects.game.mania.maniaPlayField")
    maniaReceptor = require("objects.game.mania.maniaReceptor")
    maniaComboCount = require("objects.game.mania.maniaComboCount")
    maniaHealthBar = require("objects.game.mania.maniaHealthBar")
    maniaHUD = require("objects.game.mania.maniaHUD")
    maniaJudgement = require("objects.game.mania.maniaJudgement")
    maniaJudgmentCount = require("objects.game.mania.maniaJudgmentCount")
    maniaComboAlert = require("objects.game.mania.maniaComboAlert")

    --slider
    sliderField = require("objects.game.slider.sliderField")
    sliderReceptor = require("objects.game.slider.sliderReceptor")

    --drums
    drumsNote = require("objects.game.drums.drumsNote")
    drumsLane = require("objects.game.drums.drumsLane")
    drumsReceptor = require("objects.game.drums.drumsReceptor")
    drumsInputButton = require("objects.game.drums.drumsInputButton")
    drumsInputField = require("objects.game.drums.drumsInputField")
    drumsApproachCircle = require("objects.game.drums.drumsApproachCircle")
    
    --menu
    menuSongButton = require("objects.menu.songButton")
    modifiersMenu = require("objects.menu.modifiersMenu")
    notificationsHandler = require("objects.menu.notificationsHandler")
    quickSettings = require("objects.menu.quickSettings")
    countdownBar = require("objects.menu.countdownBar")
    lyricsDisplay = require("objects.menu.lyricsDisplay")
    lyricsRenderer = require("objects.menu.lyricsRenderer") -- haha it says ass
    jukeboxSongButton = require("objects.menu.jukeboxSongButton")

    --UI
    UIsquiglyLine = require("objects.UI.UIsquiglyLine")  -- UIslop
    cursor = require("objects.UI.cursor")
    SMWCloudThingyAnimation = require("objects.UI.notGivingAwayWhatThisIs")  -- this would also be UIslop if it wasnt unused (it was fully planned to be used tho.. i just have no idea where this would fit (it also is broken as hell))
    UITimeRemaing = require("objects.UI.UITimeRemaining")
    button = require("objects.UI.button")
    socialButton = require("objects.UI.socialButton")
    toggle = require("objects.UI.toggle")
    buttonSlideOut = require("objects.UI.buttonSlideOutNew")
    notification = require("objects.UI.notification")
    UILayerWave = require("objects.UI.UILayerWave")  -- UIslop the fucking sequel 
    UISquigleCircle = require("objects.UI.UISquigleCircle")  -- i dont even need to say it again
    throbbert = require("objects.UI.throbbert")
    toggleSettings = require("objects.UI.toggleSettings")
    UIlogoH = require("objects.UI.logoH")
    window = require("objects.UI.window")
    coolFuckingRectangle = require("objects.UI.coolFuckingRectangle")
    newAlert = require("objects.UI.newAlert")    --this one is actually UIslop   (i call everything that i add to just make the UIs look more "full" UIslop, but the other ones are good additions at least, this one is just bad, so its especially UIslop)
    volumeControl = require("objects.UI.volumeControl")
    growingCircleObjectThingyIdfk = require("objects.UI.growingCircleObjectThingyIdfk")  -- this one is the most slop of all the UIslop i swear to god, i literally am stealing this from a vocaloid music video i saw,, and its my first time using bezier curves so im prob doing everuthing wrong
    growingSquare = require("objects.UI.growingAwesomeFuckingSQAURE!!!")

    settingsbaseshitthingy = require("objects.settings.settingsbaseshitthingy")
    settingsTabButton = require("objects.settings.tabButton")
    settingsModeSeperator = require("objects.settings.modeSeperator")
    settingsPreview = require("objects.settings.preview")
    settingDescription = require("objects.settings.description")
    settingsToggle = require("objects.settings.toggle")
    settingsSlider = require("objects.settings.slider")
    settingsDropdown = require("objects.settings.dropdown")
    settingsScrollbar = require("objects.settings.scrollBar")
    settingsExitButton = require("objects.settings.exitButton")