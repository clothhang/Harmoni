---@diagnostic disable: undefined-global

Skin = {   -- i need to remove lots of these tbh..
    Params = {
        ["Note Size"] = 125,
        ["Hold Size"] = 125,
        ["HoldEnd Size"] = 125,
        ["Receptor Size"] = 125,

        ["Judgement Size"] = 1.25,
        ["Judgement Y Offset"] = getScreenCenter().y,
        ["Judgement X Offset"] = getScreenCenter().x,

        ["Combo Y Offset"] = getScreenCenter().y+130,
        ["Combo X Offset"] = getScreenCenter().x,
        ["Combo Format"] = "Short",
        ["Remove Combo Stack"] = true,

        ["Hit Error Meter Y"] = 0,
        ["Hit Error Meter X"] = 0,
        ["Hit Error Meter Height"] = 15,
        ["Hit Error Meter Width"] = 150,
        ["Hit Error Meter Solid"] = false,
        ["Hit Error Meter Fade"] = 1000,

        ["Note Underlay Color"] = rgb {0, 0, 0},

        ["Judgement Counter Bump Amount"] = 50,
        ["Judgement Bump Amount"] = -70,
        ["Judgement Bump Tween Type"] = "out-back",
        ["Judgement Bump Time"] = 0.5,
        ["Judgement Counter Spacing"] = 60,
        ["Judgement Counter X"] = getScreenCenter().x - 210,
        ["Judgement Counter Y"] = getScreenCenter().y-150,

        ["Health Bar X Offset"] = getScreenCenter().x+650,
        ["Health Bar Y Offset"] = getScreenDimensions().height-100,
        ["Health Bar Height"] = 1250,
        ["Health Bar Width"] = 40,
        ["Health Bar Direction"] = "vertical",

        ["Combo Alert Start X"] = getScreenDimensions().width + 200,  -- this should always be off screen unless youre fucking weird
        ["Combo Alert Start Y"] = getScreenDimensions().height/2,
        ["Combo Alert Target X"] = getScreenDimensions().width - 300,
        ["Combo Alert Target Y"] = getScreenDimensions().height/2,
        ["Combo Alert Font Size"] = 75,

        ["Judgement Count Height"] = 750,
        ["Judgement Count X"] = 20,
        ["Judgement Count Y"] = getScreenDimensions().height/2-375,
        ["Judgement Count Square Width"] = 240,
        ["Judgement Count Square Height"] = 90,

        
        ["Perfect Color"] = rgb {191, 254, 255},
        ["Great Color"] = rgb {0, 118, 255},
        ["Good Color"] = rgb {111, 255, 158},
        ["Alright Color"] = rgb {112, 40, 78},
        ["Awful Color"] = rgb {115, 6, 6},
        ["Miss Color"] = rgb {67, 31, 31},
    },

    FontsLegacy = {
        ["HUD Large"] = newFont("FONTS/Novamono-njdg.ttf", 65),
        ["HUD Small"] = newFont("FONTS/Novamono-njdg.ttf", 15),
        ["HUD Extra Small"] = newFont("FONTS/Novamono-njdg.ttf", 12),
        ["Combo"] = newFont("FONTS/SourceCodePro-Medium.ttf", 65),
        ["Menu Extra Extra Large"] = newFont("FONTS/astonpolizregular.ttf", 75),  -- what am i even doing at this point
        ["Menu Extra Large"] = newFont("FONTS/astonpolizregular.ttf", 50),
        ["Menu Large"] = newFont("FONTS/astonpolizregular.ttf", 30),
        ["Menu Small"] = newFont("FONTS/astonpolizregular.ttf", 20),
        ["Menu Extra Small"] = newFont("FONTS/astonpolizregular.ttf", 12),
        ["Judgement Counter"] = newFont("FONTS/Novamono-njdg.ttf", 60),
    },

    Fonts = {
        ["HUD"] = "FONTS/Courier Prime Sans/Courier Prime Sans Bold.ttf",
        ["Combo"] = "FONTS/Courier Prime Sans/Courier Prime Sans Bold.ttf",
        ["Menu"] = "FONTS/neweresterfont.ttf",
        ["Judgement Counter"] = "FONTS/Courier Prime Sans/Courier Prime Sans Bold.ttf",  -- we really using the same font for fucking everyuthing
        ["Combo Alert"] = "FONTS/Courier Prime Sans/Courier Prime Sans Bold.ttf",

    },

    Notes = {
        ["4K"] = {
            ["Left"] = newQuad("Arrows", 602, 0, 300, 300),
            ["Down"] = newQuad("Arrows", 301, 0, 300, 300),
            ["Right"] = newQuad("Arrows", 903, 0, 300, 300),
            ["Up"] = newQuad("Arrows", 0, 301, 300, 300),
        },
        ["7K"] = {
            ["Left1"] = newQuad("Arrows", 602, 0, 300, 300),
            ["Down"] = newQuad("Arrows", 301, 0, 300, 300),
            ["Right1"] = newQuad("Arrows", 903, 0, 300, 300),
            ["Center"] = newQuad("Arrows", 903, 0, 300, 300),
            ["Left2"] = newQuad("Arrows", 602, 0, 300, 300),
            ["Up"] = newQuad("Arrows", 0, 301, 300, 300),
            ["Right2"] = newQuad("Arrows", 903, 0, 300, 300),
        }
    },

    HoldNotes = {
        ["4K"] = {
            ["Left"] = newQuad("Arrows", 0, 0, 300, 300),
            ["Down"] = newQuad("Arrows", 0, 0, 300, 300),
            ["Right"] = newQuad("Arrows", 0, 0, 300, 300),
            ["Up"] = newQuad("Arrows", 0, 0, 300, 300),
        },
        ["7K"] = {
            ["Left1"] = newQuad("Arrows", 0, 0, 300, 300),
            ["Down"] = newQuad("Arrows", 0, 0, 300, 300),
            ["Right1"] = newQuad("Arrows", 0, 0, 300, 300),
            ["Center"] = newQuad("Arrows", 0, 0, 300, 300),
            ["Left2"] = newQuad("Arrows", 0, 0, 300, 300),
            ["Up"] = newQuad("Arrows", 0, 0, 300, 300),
            ["Right2"] = newQuad("Arrows", 0, 0, 300, 300),
        }
    },

    HoldEndNotes = {
        ["4K"] = {
            ["Left"] = newQuad("Arrows", 602, 903, 300, 300),
            ["Down"] = newQuad("Arrows", 602, 903, 300, 300),
            ["Right"] = newQuad("Arrows", 602, 903, 300, 300),
            ["Up"] = newQuad("Arrows", 602, 903, 300, 300),
        },
        ["7K"] = {
            ["Left1"] = newQuad("Arrows", 602, 903, 300, 300),
            ["Down"] = newQuad("Arrows", 602, 903, 300, 300),
            ["Right1"] = newQuad("Arrows", 602, 903, 300, 300),
            ["Center"] = newQuad("Arrows", 602, 903, 300, 300),
            ["Left2"] = newQuad("Arrows", 602, 903, 300, 300),
            ["Up"] = newQuad("Arrows", 602, 903, 300, 300),
            ["Right2"] = newQuad("Arrows", 602, 903, 300, 300),
        }
    },

    Receptors = {
        Up = {
            ["4K"] = {
                ["Left"] = newQuad("Arrows", 602, 301, 300, 300),
                ["Down"] = newQuad("Arrows", 301, 301, 300, 300),
                ["Right"] = newQuad("Arrows", 903, 602, 300, 300),
                ["Up"] = newQuad("Arrows", 301, 903, 300, 300),
            },
            ["7K"] = {
                ["Left1"] = newQuad("Arrows", 602, 301, 300, 300),
                ["Down"] = newQuad("Arrows", 301, 301, 300, 300),
                ["Right1"] = newQuad("Arrows", 903, 602, 300, 300),
                ["Center"] = newQuad("Arrows", 903, 602, 300, 300),
                ["Left2"] = newQuad("Arrows", 602, 301, 300, 300),
                ["Up"] = newQuad("Arrows", 301, 903, 300, 300),
                ["Right2"] = newQuad("Arrows", 903, 602, 300, 300),
            }
        },
        Down = {
            ["4K"] = {
                ["Left"] = newQuad("Arrows", 0, 602, 300, 300),
                ["Down"] = newQuad("Arrows", 903, 301, 300, 300),
                ["Up"] = newQuad("Arrows", 602, 602, 300, 300),
                ["Right"] = newQuad("Arrows", 301, 602, 300, 300),
            },
            ["7K"] = {
                ["Left1"] = newQuad("Arrows", 0, 602, 300, 300),
                ["Down"] = newQuad("Arrows", 903, 301, 300, 300),
                ["Right1"] = newQuad("Arrows", 602, 602, 300, 300),
                ["Center"] = newQuad("Arrows", 602, 602, 300, 300),
                ["Left2"] = newQuad("Arrows", 0, 602, 300, 300),
                ["Up"] = newQuad("Arrows", 903, 301, 300, 300),
                ["Right2"] = newQuad("Arrows", 602, 602, 300, 300),
            }
        }
    },

    Judgements = {
        ["Perfect"] = newQuad("Judgements", 0, 332, 349, 59),
        ["Great"] = newQuad("Judgements", 0, 272, 242, 59),
        ["Good"] = newQuad("Judgements", 0, 212, 335, 59),
        ["Alright"] = newQuad("Judgements", 0, 151, 209, 60),
        ["Awful"] = newQuad("Judgements", 0, 79, 295, 71),
        ["Miss"] = newQuad("Judgements", 0, 0, 237, 78),
    },

    Particles = {
        ["Note Splash"] = newImage("PARTICLES/circle.png"),
        ["Combo Alert"] = newImage("PARTICLES/the  o r b.png"),
        ["Health Particle"] = newImage("PARTICLES/lightDot.png"),
    },

    Menu = {
        ["Main Logo"] = newImage("MENU/main logo.png"),
        ["H"] = newImage("MENU/H.png"),
        ["Icon Logo"] = newImage("MENU/logoH.png"),
        ["Loading Spinner"] = newImage("MENU/logoH.png"),
        ["Background"] = newImage("MENU/TITLEBG/1.png")
    },

    Results = {
        ["Circle Empty"] = newImage("RESULTS/empty circle.png"),
        ["Circle Fill"] = newImage("RESULTS/fill circle.png"),
    },
    
    RandomBackgrounds = {
        newImage("MENU/backgrounds/1.png"),
        newImage("MENU/backgrounds/8.png"),
        newImage("MENU/backgrounds/9.png"),
    },

    Sounds = {
        ["First Miss"] = nil,  -- some day
        ["Miss"] = nil,
        ["Menu Scroll"] = nil,
        ["Hit Sound"] = nil,
        ["Tap Sound"] = nil,
    },

    Colors = {
        ["Song Button Fill"] = {0, 0, 0, 0.7},
        ["Song Button Line"] = {0.8, 0.8, 0.8, 1},
        ["Song Button Text"] = {1, 1, 1, 1},

        ["Difficulty Button Fill"] = {0, 0, 0, 0.7},
        ["Difficulty Button Line"] = {0.8, 0.8, 0.8, 1},
        ["Difficulty Button Text"] = {1, 1, 1, 1},

        ["Song Info Box Fill"] = {0, 0, 0, 0.7},
        ["Song Info Box Line"] = {0.8, 0.8, 0.8, 1},
        ["Song Info Box Text"] = {1, 1, 1, 1},

        ["List Menu Backing Fill"] = {0, 0, 0, 0.7},
        ["List Menu Backing Line"] = {0.8, 0.8, 0.8, 1},
        ["List Menu Button Fill"] = {0, 0, 0, 0.7},
        ["List Menu Button Line"] = {0.8, 0.8, 0.8, 1},
        ["List Menu Text"] = {1, 1, 1, 1},

        ["Modifiers Menu Backing Fill"] = {0, 0, 0, 0.7},
        ["Modifiers Menu Backing Line"] = {0.8, 0.8, 0.8, 1},
        ["Modifiers Menu Button Fill"] = {0, 0, 0, 0.7},
        ["Modifiers Menu Button Line"] = {0.8, 0.8, 0.8, 1},
        ["Modifiers Menu Text"] = {1, 1, 1, 1},

        ["Song Select Tabs Fill"] = {0, 0, 0, 0.7},
        ["Song Select Tabs Line"] = {0.8, 0.8, 0.8, 1},
        ["Song Select Tabs Text"] = {1, 1, 1, 1},
    },

    RandomColors = {
        {240/255, 323/255, 205/255, 0.25},  -- 240/323/205
        {219/255, 213/255, 185/255, 0.25},  -- 219/213/185
        {192/255, 186/255, 153/255, 0.25},  -- 192/186/153
        {254/255, 235/255, 201/255, 0.25},  -- 254/235/201
        {253/255, 203/255, 162/255, 0.25},  -- 253/203/162
        {252/255, 169/255, 133/255, 0.25},  -- 252/169/133
        {125/255, 255/255, 76/255, 0.25},   -- 125/255/76
        {255/255, 250/255, 19/255, 0.25},   -- 255/250/19
        {255/255, 237/255, 81/255, 0.25},   -- 255/237/81
        {224/255, 243/255, 176/255, 0.25},  -- 224/243/176
        {191/255, 228/255, 18/255, 0.25},   -- 191/228/18
        {133/255, 202/255, 93/255, 0.25},   -- 133/202/93
        {207/255, 236/255, 207/255, 0.25},  -- 207/236/207
        {181/255, 235/255, 174/255, 0.25},  -- 181/235/174
        {145/255, 210/255, 144/255, 0.25},  -- 145/210/144
        {179/255, 226/255, 221/255, 0.25},  -- 179/226/221
        {134/255, 207/255, 190/255, 0.25},  -- 134/207/190
        {72/255, 181/255, 163/255, 0.25},   -- 72/181/163
        {20/255, 173/255, 207/255, 0.25},   -- 20/173/207
        {18/255, 225/255, 174/255, 0.25},   -- 18/225/174
        {14/255, 210/255, 144/255, 0.25},   -- 14/210/144
        {179/255, 226/255, 21/255, 0.25},   -- 179/226/21
        {134/255, 207/255, 79/255, 0.25},   -- 134/207/79
        {72/255, 181/255, 63/255, 0.25},    -- 72/181/63
        {15/255, 106/255, 239/255, 0.25},   -- 15/106/239
        {154/255, 206/255, 235/255, 0.25},  -- 154/206/235
        {111/255, 183/255, 214/255, 0.25},  -- 111/183/214
        {191/255, 213/255, 232/255, 0.25},  -- 191/213/232
        {148/255, 168/255, 208/255, 0.25},  -- 148/168/208
        {117/255, 137/255, 191/255, 0.25},  -- 117/137/191
    }
}