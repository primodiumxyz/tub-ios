type TokenMetadata = {
  name: string;
  symbol: string;
  uri: string;
  supply: string;
};

export const getRandomTokenMetadata = (index?: number): TokenMetadata => {
  const randomIndex = index ?? Math.floor(Math.random() * TOKENS_METADATA.length);
  const supply = Math.floor(Math.random() * 1000000000).toString();
  return { ...TOKENS_METADATA[randomIndex], supply } as TokenMetadata;
};

export const TOKENS_METADATA = [
  {
    name: "DogeMoon",
    symbol: "DOGEMN",
    uri: "https://solana.mock/token/DOGEMN",
  },
  {
    name: "MemeCoin",
    symbol: "MEME",
    uri: "https://solana.mock/token/MEME",
  },
  {
    name: "HODLersUnited",
    symbol: "HODL",
    uri: "https://solana.mock/token/HODL",
  },
  {
    name: "ShibaRise",
    symbol: "SHIBAR",
    uri: "https://solana.mock/token/SHIBAR",
  },
  {
    name: "LamboToken",
    symbol: "LAMBO",
    uri: "https://solana.mock/token/LAMBO",
  },
  {
    name: "MoonQuest",
    symbol: "MOONQ",
    uri: "https://solana.mock/token/MOONQ",
  },
  {
    name: "PepeCash",
    symbol: "PEPEC",
    uri: "https://solana.mock/token/PEPEC",
  },
  {
    name: "StonksUp",
    symbol: "STONK",
    uri: "https://solana.mock/token/STONK",
  },
  {
    name: "ToTheMars",
    symbol: "MARSS",
    uri: "https://solana.mock/token/MARSS",
  },
  {
    name: "RocketFuel",
    symbol: "RFUEL",
    uri: "https://solana.mock/token/RFUEL",
  },
  {
    name: "CatNip",
    symbol: "CATNIP",
    uri: "https://solana.mock/token/CATNIP",
  },
  {
    name: "BananaCoin",
    symbol: "BANANA",
    uri: "https://solana.mock/token/BANANA",
  },
  {
    name: "WowToken",
    symbol: "WOW",
    uri: "https://solana.mock/token/WOW",
  },
  {
    name: "YOLOFund",
    symbol: "YOLO",
    uri: "https://solana.mock/token/YOLO",
  },
  {
    name: "RarePepes",
    symbol: "RPEPE",
    uri: "https://solana.mock/token/RPEPE",
  },
  {
    name: "EpicBacon",
    symbol: "BACON",
    uri: "https://solana.mock/token/BACON",
  },
  {
    name: "OneDoesNotSimply",
    symbol: "ODNS",
    uri: "https://solana.mock/token/ODNS",
  },
  {
    name: "TrollFace",
    symbol: "TROLL",
    uri: "https://solana.mock/token/TROLL",
  },
  {
    name: "GrumpyCat",
    symbol: "GRUMPY",
    uri: "https://solana.mock/token/GRUMPY",
  },
  {
    name: "NyanCat",
    symbol: "NYAN",
    uri: "https://solana.mock/token/NYAN",
  },
  {
    name: "SuccessKid",
    symbol: "SCKID",
    uri: "https://solana.mock/token/SCKID",
  },
  {
    name: "KeyboardCat",
    symbol: "KEYCAT",
    uri: "https://solana.mock/token/KEYCAT",
  },
  {
    name: "BadLuckBrian",
    symbol: "BLBRI",
    uri: "https://solana.mock/token/BLBRI",
  },
  {
    name: "Philosoraptor",
    symbol: "PHILO",
    uri: "https://solana.mock/token/PHILO",
  },
  {
    name: "Over9000",
    symbol: "O9000",
    uri: "https://solana.mock/token/O9000",
  },
  {
    name: "RickRollCoin",
    symbol: "RICK",
    uri: "https://solana.mock/token/RICK",
  },
  {
    name: "ForeverAlone",
    symbol: "FALONE",
    uri: "https://solana.mock/token/FALONE",
  },
  {
    name: "DerpCoin",
    symbol: "DERP",
    uri: "https://solana.mock/token/DERP",
  },
  {
    name: "FacepalmToken",
    symbol: "PALM",
    uri: "https://solana.mock/token/PALM",
  },
  {
    name: "AwkwardSeal",
    symbol: "ASEAL",
    uri: "https://solana.mock/token/ASEAL",
  },
  {
    name: "HideThePain",
    symbol: "HAROLD",
    uri: "https://solana.mock/token/HAROLD",
  },
  {
    name: "DistractedBF",
    symbol: "DBF",
    uri: "https://solana.mock/token/DBF",
  },
  {
    name: "SpongeMock",
    symbol: "SPONGE",
    uri: "https://solana.mock/token/SPONGE",
  },
  {
    name: "ExpandingBrain",
    symbol: "XBRN",
    uri: "https://solana.mock/token/XBRN",
  },
  {
    name: "RollSafe",
    symbol: "RSAFE",
    uri: "https://solana.mock/token/RSAFE",
  },
  {
    name: "IsThisAPigeon",
    symbol: "PIGEON",
    uri: "https://solana.mock/token/PIGEON",
  },
  {
    name: "ChangeMyMind",
    symbol: "CMM",
    uri: "https://solana.mock/token/CMM",
  },
  {
    name: "SurprisedPikachu",
    symbol: "PIKACHU",
    uri: "https://solana.mock/token/PIKACHU",
  },
  {
    name: "DatBoi",
    symbol: "DATBOI",
    uri: "https://solana.mock/token/DATBOI",
  },
  {
    name: "KermitSipping",
    symbol: "KERMIT",
    uri: "https://solana.mock/token/KERMIT",
  },
  {
    name: "ArthurFist",
    symbol: "AFIST",
    uri: "https://solana.mock/token/AFIST",
  },
  {
    name: "ThisIsFine",
    symbol: "FINE",
    uri: "https://solana.mock/token/FINE",
  },
  {
    name: "EvilKermit",
    symbol: "EKERMIT",
    uri: "https://solana.mock/token/EKERMIT",
  },
  {
    name: "DrakePreference",
    symbol: "DRAKE",
    uri: "https://solana.mock/token/DRAKE",
  },
  {
    name: "ConfusedNick",
    symbol: "CNICK",
    uri: "https://solana.mock/token/CNICK",
  },
  {
    name: "LeftShark",
    symbol: "LSHARK",
    uri: "https://solana.mock/token/LSHARK",
  },
  {
    name: "SaltBae",
    symbol: "SALT",
    uri: "https://solana.mock/token/SALT",
  },
  {
    name: "ConfusedMathLady",
    symbol: "CMLADY",
    uri: "https://solana.mock/token/CMLADY",
  },
  {
    name: "SuccessPenguin",
    symbol: "SPENG",
    uri: "https://solana.mock/token/SPENG",
  },
  {
    name: "FuturamaFry",
    symbol: "FRY",
    uri: "https://solana.mock/token/FRY",
  },
  {
    name: "DisappointedDad",
    symbol: "DAD",
    uri: "https://solana.mock/token/DAD",
  },
  {
    name: "AncientAliens",
    symbol: "ALIEN",
    uri: "https://solana.mock/token/ALIEN",
  },
  {
    name: "PhilosopherCat",
    symbol: "PCAT",
    uri: "https://solana.mock/token/PCAT",
  },
  {
    name: "HoneyBadger",
    symbol: "HBADGER",
    uri: "https://solana.mock/token/HBADGER",
  },
  {
    name: "GangnamStyle",
    symbol: "PSY",
    uri: "https://solana.mock/token/PSY",
  },
  {
    name: "HarlemShake",
    symbol: "HARLEM",
    uri: "https://solana.mock/token/HARLEM",
  },
  {
    name: "PlankingCoin",
    symbol: "PLANK",
    uri: "https://solana.mock/token/PLANK",
  },
  {
    name: "IceBucket",
    symbol: "ICE",
    uri: "https://solana.mock/token/ICE",
  },
  {
    name: "CharlieBitMe",
    symbol: "CHARLIE",
    uri: "https://solana.mock/token/CHARLIE",
  },
  {
    name: "MannequinChallenge",
    symbol: "MANNE",
    uri: "https://solana.mock/token/MANNE",
  },
  {
    name: "DressBlueGold",
    symbol: "DRESS",
    uri: "https://solana.mock/token/DRESS",
  },
  {
    name: "LaurelYanny",
    symbol: "AUDIO",
    uri: "https://solana.mock/token/AUDIO",
  },
  {
    name: "BabyShark",
    symbol: "BSHARK",
    uri: "https://solana.mock/token/BSHARK",
  },
  {
    name: "Area51Raid",
    symbol: "NARUTO",
    uri: "https://solana.mock/token/NARUTO",
  },
  {
    name: "CoffinDance",
    symbol: "COFFIN",
    uri: "https://solana.mock/token/COFFIN",
  },
  {
    name: "BernieMittens",
    symbol: "BERNIE",
    uri: "https://solana.mock/token/BERNIE",
  },
  {
    name: "TheyDontKnow",
    symbol: "TDK",
    uri: "https://solana.mock/token/TDK",
  },
  {
    name: "MockingSpongeBob",
    symbol: "MOCK",
    uri: "https://solana.mock/token/MOCK",
  },
  {
    name: "YodelKid",
    symbol: "YODEL",
    uri: "https://solana.mock/token/YODEL",
  },
  {
    name: "PanikKalm",
    symbol: "PANIK",
    uri: "https://solana.mock/token/PANIK",
  },
  {
    name: "GalaxyBrain",
    symbol: "GXBRAIN",
    uri: "https://solana.mock/token/GXBRAIN",
  },
  {
    name: "MikeWazowski",
    symbol: "MIKE",
    uri: "https://solana.mock/token/MIKE",
  },
  {
    name: "UNOReverse",
    symbol: "UNO",
    uri: "https://solana.mock/token/UNO",
  },
  {
    name: "BigBrain",
    symbol: "BRAIN",
    uri: "https://solana.mock/token/BRAIN",
  },
  {
    name: "HappyDoggo",
    symbol: "DOGGO",
    uri: "https://solana.mock/token/DOGGO",
  },
  {
    name: "MaskOff",
    symbol: "MASK",
    uri: "https://solana.mock/token/MASK",
  },
  {
    name: "ZoomCat",
    symbol: "ZCAT",
    uri: "https://solana.mock/token/ZCAT",
  },
  {
    name: "DogeToTheMoon",
    symbol: "DTTM",
    uri: "https://solana.mock/token/DTTM",
  },
  {
    name: "WholesomeSeal",
    symbol: "WSEAL",
    uri: "https://solana.mock/token/WSEAL",
  },
  {
    name: "PogChamp",
    symbol: "POG",
    uri: "https://solana.mock/token/POG",
  },
  {
    name: "BlinkingGuy",
    symbol: "BLINK",
    uri: "https://solana.mock/token/BLINK",
  },
  {
    name: "SideEyeChloe",
    symbol: "CHLOE",
    uri: "https://solana.mock/token/CHLOE",
  },
  {
    name: "HideThePainAgain",
    symbol: "HTPA",
    uri: "https://solana.mock/token/HTPA",
  },
  {
    name: "EvilToddler",
    symbol: "ETOD",
    uri: "https://solana.mock/token/ETOD",
  },
  {
    name: "Ermahgerd",
    symbol: "ERMAH",
    uri: "https://solana.mock/token/ERMAH",
  },
  {
    name: "FirstWorldProblems",
    symbol: "FWP",
    uri: "https://solana.mock/token/FWP",
  },
  {
    name: "ImaginationSpongeBob",
    symbol: "IMAGINE",
    uri: "https://solana.mock/token/IMAGINE",
  },
  {
    name: "UnhelpfulHighSchool",
    symbol: "UHS",
    uri: "https://solana.mock/token/UHS",
  },
  {
    name: "MeGusta",
    symbol: "GUSTA",
    uri: "https://solana.mock/token/GUSTA",
  },
  {
    name: "GrumpyCat2",
    symbol: "GCAT2",
    uri: "https://solana.mock/token/GCAT2",
  },
  {
    name: "OofCoin",
    symbol: "OOF",
    uri: "https://solana.mock/token/OOF",
  },
  {
    name: "BongoCat",
    symbol: "BONGO",
    uri: "https://solana.mock/token/BONGO",
  },
  {
    name: "MrKrabsBlur",
    symbol: "KRABS",
    uri: "https://solana.mock/token/KRABS",
  },
  {
    name: "SwoleDog",
    symbol: "SWOLE",
    uri: "https://solana.mock/token/SWOLE",
  },
  {
    name: "Cheems",
    symbol: "CHEEMS",
    uri: "https://solana.mock/token/CHEEMS",
  },
  {
    name: "CryingCat",
    symbol: "CCAT",
    uri: "https://solana.mock/token/CCAT",
  },
  {
    name: "GigaChad",
    symbol: "CHAD",
    uri: "https://solana.mock/token/CHAD",
  },
  {
    name: "AmongUs",
    symbol: "SUS",
    uri: "https://solana.mock/token/SUS",
  },
  {
    name: "DoomScroll",
    symbol: "DOOM",
    uri: "https://solana.mock/token/DOOM",
  },
  {
    name: "CatJAM",
    symbol: "CJAM",
    uri: "https://solana.mock/token/CJAM",
  },
];
