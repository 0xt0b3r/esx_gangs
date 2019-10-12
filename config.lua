Config = {}

Config.DrawDistance = 140 --[ Marker visibility ]

Config.Gangs = {
    example_gang = {
        society = "society_example", -- [ esx_Society name ]
        JobName = "example_gang", -- [ esx_Job name ]
        JobLabel = "Example Gang", -- [ Label ]
        Blip = { -- [ Map Blip for gang house/location ]
            coords = vector3(0, 0, 0),
            sprite = 366,
            scale = 0.8,
            color = 59,
            name = "Example Gang Blip",
        },
        Markers = { -- [ Markers for gang management/etc. ]
            Color = {r = 0, g = 0, b = 0}, -- [ Color of markers ]
            boss = { -- [Society actions]
                name = "boss",
                coords = {x = 0,y = 0,z = 0},
                label = "Boss Actions"
            },
            armory = { --[ Item + Weapon storage ]
                name = "armory",
                coords = {x = 0, y = 0, z = 0},
                label = "Armory"
            }
        }
    }
}