"""Build Zoomdle/Resources/words.json from puzzles + a game-sized noun dictionary."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(r"D:\Home\AI Projects\Zoomdle")
PUZZLES = ROOT / "Zoomdle" / "Resources" / "puzzles.json"
OUT = ROOT / "Zoomdle" / "Resources" / "words.json"


def title_case(word: str) -> str:
    word = re.sub(r"\s+", " ", word.strip())
    if not word:
        return word
    small = {"a", "an", "and", "of", "the", "de", "la", "el", "st", "st."}
    parts = word.split(" ")
    out = []
    for i, part in enumerate(parts):
        lower = part.lower()
        if i > 0 and lower in small:
            out.append(lower)
        else:
            out.append(part[:1].upper() + part[1:].lower() if part else part)
    return " ".join(out)


def unique_keep_order(words: list[str]) -> list[str]:
    seen: set[str] = set()
    ordered: list[str] = []
    for raw in words:
        cleaned = re.sub(r"\s+", " ", raw.strip())
        if len(cleaned) < 2:
            continue
        key = cleaned.lower()
        if key in seen:
            continue
        seen.add(key)
        ordered.append(title_case(cleaned))
    return ordered


def puzzle_answers() -> list[str]:
    data = json.loads(PUZZLES.read_text(encoding="utf-8"))
    words: list[str] = []
    for puzzle in data:
        words.append(puzzle["answer"])
        words.extend(puzzle.get("acceptableAnswers") or [])
    return words


def dictionary() -> list[str]:
    animals = [
        "aardvark", "albatross", "alligator", "alpaca", "anaconda", "angelfish", "ant", "anteater",
        "antelope", "ape", "armadillo", "baboon", "badger", "barracuda", "bat", "beagle", "bear",
        "beaver", "bee", "beetle", "bison", "blackbird", "blue jay", "bluebird", "boar", "bobcat",
        "bonobo", "buffalo", "butterfly", "buzzard", "camel", "canary", "capybara", "caribou",
        "catfish", "centipede", "chameleon", "cheetah", "chicken", "chimpanzee", "chinchilla",
        "chipmunk", "cicada", "clam", "clownfish", "cobra", "cockatoo", "cockroach", "cod",
        "condor", "cougar", "cow", "coyote", "crab", "crane", "crayfish", "cricket", "crocodile",
        "crow", "cuckoo", "cuttlefish", "dalmatian", "deer", "dingo", "dinosaur", "dolphin",
        "donkey", "dove", "dragonfly", "duck", "dugong", "eagle", "earthworm", "eel", "egret",
        "elephant", "elk", "emu", "falcon", "ferret", "finch", "firefly", "flamingo", "flea",
        "flounder", "fly", "fox", "frog", "gazelle", "gecko", "gerbil", "giraffe", "gnat", "goat",
        "goldfish", "goose", "gopher", "gorilla", "grasshopper", "great dane", "greyhound",
        "grizzly bear", "guinea pig", "gull", "hamster", "hare", "hawk", "hedgehog", "heron",
        "hippo", "hippopotamus", "hornet", "horse", "horsefly", "hummingbird", "hyena", "ibis",
        "iguana", "impala", "jackal", "jackrabbit", "jaguar", "jay", "jellyfish", "kangaroo",
        "kingfisher", "kiwi", "koala", "komodo dragon", "kookaburra", "krill", "ladybug",
        "lemur", "leopard", "lion", "lizard", "llama", "lobster", "lynx", "macaw", "magpie",
        "mallard", "manatee", "mandrill", "mantis", "meerkat", "mink", "mole", "mongoose",
        "monkey", "moose", "mosquito", "moth", "mouse", "mule", "muskrat", "mussel", "narwhal",
        "newt", "nightingale", "ocelot", "octopus", "opossum", "orangutan", "orca", "ostrich",
        "otter", "owl", "ox", "oyster", "panda", "panther", "parrot", "partridge", "peacock",
        "pelican", "penguin", "pheasant", "pig", "pigeon", "pike", "piranha", "platypus",
        "polar bear", "pony", "poodle", "porcupine", "porpoise", "prairie dog", "prawn",
        "praying mantis", "puffin", "puma", "python", "quail", "rabbit", "raccoon", "ram",
        "rat", "rattlesnake", "raven", "reindeer", "rhino", "rhinoceros", "roadrunner", "robin",
        "rooster", "salamander", "salmon", "sandpiper", "sardine", "scorpion", "seahorse",
        "seal", "sea lion", "sea urchin", "shark", "sheep", "shrimp", "skunk", "sloth", "slug",
        "snail", "snake", "sparrow", "spider", "sponge", "squid", "squirrel", "starfish",
        "stingray", "stork", "swallow", "swan", "swordfish", "tapir", "tarantula", "termite",
        "tiger", "toad", "tortoise", "toucan", "trout", "tuna", "turkey", "turtle", "viper",
        "vulture", "walrus", "wasp", "weasel", "whale", "wolf", "wolverine", "wombat",
        "woodpecker", "worm", "wren", "yak", "zebra", "bulldog", "labrador", "husky",
        "german shepherd", "corgi", "siamese cat", "persian cat", "scottish fold", "maine coon",
        "golden retriever", "border collie", "boxer", "chihuahua", "pug", "rottweiler",
        "saint bernard", "dalmatian", "bengal tiger", "snow leopard", "red panda", "giant panda",
        "bald eagle", "blue whale", "humpback whale", "great white shark", "hammerhead shark",
        "king cobra", "diamondback", "american bison", "mountain goat", "bighorn sheep",
        "arctic fox", "red fox", "gray wolf", "timber wolf", "black bear", "brown bear",
        "koala bear", "honeybee", "bumblebee", "monarch butterfly", "luna moth", "dragon",
        "unicorn", "phoenix", "griffin", "yeti", "bigfoot", "loch ness monster", "sphinx",
        "kitten", "puppy", "foal", "calf", "lamb", "cub", "chick", "tadpole", "hatchling",
        "house cat", "tabby", "tabby cat", "alley cat", "barnyard owl", "barn owl", "snowy owl",
        "great horned owl", "macaroni penguin", "emperor penguin", "adelie penguin"
    ]

    foods = [
        "apple", "apricot", "avocado", "bacon", "bagel", "baguette", "banana", "barbecue",
        "basil", "beef", "beet", "berry", "biscuit", "blackberry", "blueberry", "bread",
        "broccoli", "brownie", "brussels sprout", "bun", "burrito", "butter", "cabbage",
        "cake", "candy", "cantaloupe", "caramel", "carrot", "cashew", "cauliflower", "celery",
        "cereal", "cheddar", "cheese", "cheesecake", "cherry", "chilli", "chip", "chocolate",
        "churro", "cinnamon roll", "clam chowder", "coconut", "coffee", "cookie", "corn",
        "corn dog", "couscous", "crab cake", "cranberry", "cream", "crepe", "croissant",
        "cucumber", "cupcake", "curry", "custard", "donut", "doughnut", "dumpling", "egg",
        "eggplant", "falafel", "fig", "fish and chips", "fondue", "french fries", "fries",
        "fruit", "fudge", "garlic", "gelato", "ginger", "granola", "grape", "grapefruit",
        "gravy", "guacamole", "gumbo", "gyro", "ham", "hamburger", "hash brown", "hazelnut",
        "honey", "hot dog", "hummus", "ice cream", "icing", "jalapeno", "jam", "jelly",
        "juice", "kale", "kebab", "ketchup", "kiwi fruit", "lasagna", "leek", "lemon",
        "lemonade", "lentil", "lettuce", "lime", "lobster roll", "lollipop", "macaron",
        "macaroni", "mango", "maple syrup", "marmalade", "marshmallow", "mashed potato",
        "meatball", "melon", "meringue", "milk", "milkshake", "mint", "muffin", "mushroom",
        "mustard", "nacho", "noodle", "nugget", "oatmeal", "olive", "omelette", "onion",
        "orange", "oyster cracker", "pancake", "papaya", "pasta", "pastry", "peach", "peanut",
        "peanut butter", "pear", "pea", "pecan", "pepper", "pepperoni", "pickle", "pie",
        "pineapple", "pita", "pizza", "plum", "pomegranate", "popcorn", "popsicle", "pork",
        "potato", "pretzel", "pudding", "pumpkin", "quesadilla", "quiche", "radish", "raisin",
        "ramen", "raspberry", "ravioli", "relish", "rice", "risotto", "roast", "roll",
        "salad", "salami", "salmon fillet", "salsa", "sandwich", "sausage", "scone", "seafood",
        "shrimp cocktail", "smoothie", "soda", "sorbet", "soup", "spaghetti", "spinach",
        "scone", "steak", "stew", "strawberry", "sugar", "sundae", "sushi", "taco", "tart",
        "tea", "toast", "tofu", "tomato", "tortilla", "truffle", "turkey sandwich", "vanilla",
        "waffle", "walnut", "watermelon", "whip cream", "wonton", "yogurt", "zucchini",
        "pepperoni pizza", "cheeseburger", "french croissant", "street taco", "sushi roll",
        "maki", "nigiri", "pho", "pad thai", "bibimbap", "empanada", "tamale", "enchilada",
        "fajita", "paella", "tapas", "bruschetta", "tiramisu", "baklava", "cannoli",
        "churros", "crepes", "escargot", "foie gras", "gazpacho", "gnocchi", "risotto",
        "samosa", "naan", "tikka masala", "biryani", "dim sum", "bao", "ramen bowl",
        "udon", "tempura", "miso soup", "edamame", "kimchi", "bulgogi", "spring roll",
        "egg roll", "fortune cookie", "mochi", "poutine", "maple muffin", "clam bake",
        "corn on the cob", "hot cocoa", "apple pie", "pumpkin pie", "key lime pie",
        "banana split", "root beer", "ginger ale", "lemonade stand", "cotton candy",
        "candy apple", "caramel corn", "onion ring", "mozzarella stick", "chicken wing",
        "buffalo wing", "caesar salad", "cobb salad", "greek salad", "club sandwich",
        "blt", "philly cheesesteak", "reuben", "hot pretzel", "soft pretzel", "baguette"
    ]

    landmarks = [
        "eiffel tower", "statue of liberty", "golden gate bridge", "mount fuji", "pyramid",
        "great pyramid", "giza", "sphinx", "big ben", "tower of london", "buckingham palace",
        "stonehenge", "colosseum", "pantheon", "leaning tower of pisa", "trevi fountain",
        "vatican", "sistine chapel", "florence duomo", "acropolis", "parthenon", "taj mahal",
        "red fort", "gateway of india", "petra", "burj khalifa", "burj al arab", "dubai frame",
        "great wall", "forbidden city", "terracotta army", "mount everest", "k2", "kilimanjaro",
        "matterhorn", "alps", "andes", "rockies", "grand canyon", "niagara falls",
        "yellowstone", "yosemite", "half dome", "el capitan", "zion", "bryce canyon",
        "monument valley", "devils tower", "mount rushmore", "liberty bell", "white house",
        "capitol building", "lincoln memorial", "washington monument", "empire state building",
        "chrysler building", "one world trade center", "brooklyn bridge", "times square",
        "central park", "hollywood sign", "golden gate", "alcatraz", "space needle",
        "gateway arch", "cn tower", "niagara", "chichen itza", "machu picchu", "easter island",
        "christ the redeemer", "sugarloaf", "iguazu falls", "amazon river", "nile",
        "sahara", "uluru", "sydney opera house", "harbour bridge", "great barrier reef",
        "tower bridge", "london eye", "arc de triomphe", "notre dame", "louvre", "sagrada familia",
        "park guell", "alhambra", "neuschwanstein", "brandenburg gate", "reichstag",
        "prague castle", "charles bridge", "st basils", "kremlin", "hagia sophia",
        "blue mosque", "cappadocia", "pamukkale", "angkor wat", "ha long bay", "mount fuji",
        "tokyo tower", "sensoji", "fushimi inari", "kinkakuji", "itsukushima shrine",
        "seoul tower", "marina bay sands", "merlion", "petronas towers", "borobudur",
        "prambanan", "table mountain", "victoria falls", "serengeti", "masai mara",
        "pyramids of giza", "valley of the kings", "luxor temple", "abu simbel",
        "moai", "chichen itza", "tikal", "palenque", "teotihuacan", "chapultepec",
        "lighthouse", "windmill", "castle", "fortress", "pagoda", "cathedral", "mosque",
        "synagogue", "temple", "chapel", "monastery", "palace", "clock tower", "bell tower",
        "drawbridge", "aqueduct", "amphitheater", "coliseum", "obelisk", "totem pole",
        "totem", "cairn", "stone arch", "natural bridge", "hot spring", "geyser",
        "old faithful", "crater lake", "lake tahoe", "lake como", "lake louise",
        "banff", "jasper", "whistler", "machu pichu", "sacre coeur", "mont saint michel",
        "cliffs of moher", "giant causeway", "hadrians wall", "edinburgh castle",
        "stirling castle", "skara brae", "callanish", "newgrange", "dover castle",
        "windsor castle", "palace of versailles", "chateau", "tudor house", "log cabin",
        "skyscraper", "pentagon", "statue of unity", "lotus temple", "golden temple",
        "mecca", "medina", "dome of the rock", "wailing wall", "dead sea", "galilee",
        "jordan river", "red sea", "black sea", "caspian sea", "mediterranean",
        "hudson bay", "cape cod", "key west", "santa monica pier", "venice beach",
        "pike place", "faneuil hall", "freedom trail", "plymouth rock", "jamestown",
        "mesa verde", "carlsbad caverns", "mammoth cave", "everglades", "denali",
        "glacier national park", "olympic peninsula", "redwood", "sequoia", "joshua tree",
        "death valley", "salt flats", "bonneville", "antelope canyon", "horseshoe bend",
        "narrows", "angels landing", "delicate arch", "cannon beach", "haystack rock"
    ]

    objects = [
        "accordion", "alarm clock", "anvil", "apron", "armchair", "arrow", "axe", "backpack",
        "balloon", "bandage", "banner", "barrel", "basket", "baton", "battery", "beaker",
        "bed", "bell", "bench", "bicycle", "binoculars", "blackboard", "blanket", "blender",
        "book", "bookmark", "boot", "bottle", "bow", "bowl", "box", "bracelet", "brick",
        "bridge", "broom", "brush", "bucket", "bullseye", "buoy", "cabinet", "cage", "calculator",
        "calendar", "camera", "candle", "candlestick", "canoe", "canvas", "cap", "cape",
        "car", "card", "carousel", "cart", "cassette", "cauldron", "chain", "chair", "chalk",
        "chalkboard", "chandelier", "chest", "chimney", "chisel", "clamp", "clipboard",
        "clock", "closet", "coat", "coin", "comb", "compass", "computer", "cone", "controller",
        "cooler", "cork", "couch", "cradle", "crayon", "crown", "crutch", "crystal", "cube",
        "cup", "curtain", "cushion", "dagger", "dart", "desk", "dice", "dishwasher", "doll",
        "door", "doorknob", "dresser", "drill", "drum", "dryer", "dumbbell", "dustpan",
        "earring", "easel", "envelope", "eraser", "escalator", "fan", "faucet", "fence",
        "fire hydrant", "fireplace", "flag", "flashlight", "flask", "flute", "folder",
        "fountain", "frame", "fridge", "funnel", "furnace", "gamepad", "gavel", "gear",
        "globe", "glove", "goggles", "gramophone", "guitar", "hammer", "hammock", "handbag",
        "hanger", "harmonica", "harp", "hat", "headphones", "helmet", "hinge", "hoe",
        "hook", "hourglass", "house", "igloo", "inkwell", "iron", "jackhammer", "jar",
        "jeep", "jewels", "jukebox", "kayak", "kettle", "key", "keyboard", "kite", "knife",
        "knob", "ladder", "lamp", "lantern", "laptop", "latch", "lawnmower", "leather",
        "lego", "lens", "letter", "level", "lightbulb", "lock", "locomotive", "loom",
        "magnet", "mailbox", "mallet", "map", "marker", "mask", "match", "mattress",
        "megaphone", "microscope", "microwave", "mirror", "mop", "motorcycle", "mug",
        "nail", "necklace", "needle", "net", "notebook", "oar", "oboe", "oil lamp",
        "oven", "paddle", "pail", "paintbrush", "palette", "pan", "paperclip", "parachute",
        "pen", "pencil", "pendulum", "piano", "pillow", "pin", "pipe", "pitchfork", "planetarium",
        "pliers", "plug", "plunger", "pocket watch", "postbox", "pot", "potter wheel",
        "printer", "projector", "pulley", "purse", "puzzle", "quill", "quilt", "radio",
        "raft", "rake", "record", "refrigerator", "remote", "ribbon", "ring", "robot",
        "rocking chair", "roller skate", "rope", "ruler", "safe", "sail", "saw", "scale",
        "scissors", "scooter", "screwdriver", "scroll", "seesaw", "sewing machine",
        "shield", "shoe", "shovel", "sign", "sink", "skateboard", "sled", "sleigh",
        "smartphone", "sofa", "speaker", "spectacles", "spoon", "stairs", "stamp",
        "stapler", "statue", "stethoscope", "stool", "stopwatch", "stove", "suitcase",
        "sunglasses", "surfboard", "swing", "sword", "syringe", "table", "tablet", "tank",
        "tape", "teacup", "teapot", "teddy bear", "telephone", "telescope", "television",
        "tent", "thimble", "throne", "tie", "timer", "toaster", "toilet", "tongs",
        "toolbox", "toothbrush", "torch", "tractor", "traffic light", "train", "tray",
        "treasure chest", "tripod", "trombone", "trophy", "trumpet", "typewriter", "umbrella",
        "urn", "vacuum", "vase", "violin", "wagon", "wallet", "watch", "watering can",
        "webcam", "well", "wheel", "wheelbarrow", "whistle", "window", "wrench", "xylophone",
        "yo-yo", "zipper", "grand piano", "acoustic guitar", "electric guitar", "drum kit",
        "cymbal", "tambourine", "ukulele", "banjo", "cello", "double bass", "saxophone",
        "clarinet", "french horn", "tuba", "bagpipes", "synthesizer", "turntable",
        "record player", "walkie talkie", "payphone", "rotary phone", "flip phone",
        "polaroid", "film camera", "dslr", "camcorder", "tripod stand", "softbox",
        "light stand", "boom mic", "headphones", "earbuds", "smartwatch", "fitness tracker",
        "meter stick", "protractor", "compass rose", "sextant", "astrolabe", "sundial",
        "abacus", "slide rule", "typewriter ribbon", "fountain pen", "ballpoint", "chalk",
        "whiteboard", "corkboard", "pushpin", "thumbtack", "binder", "folder", "briefcase",
        "satchel", "duffel bag", "suitcase", "trunk", "chest of drawers", "nightstand",
        "coffee table", "dining table", "bar stool", "beanbag", "futon", "bunk bed",
        "crib", "high chair", "stroller", "car seat", "booster seat", "playpen",
        "fire extinguisher", "smoke alarm", "carbon detector", "first aid kit",
        "band aid", "thermometer", "scale", "bathroom scale", "tape measure",
        "swiss army knife", "multitool", "flashlight", "headlamp", "lantern", "torch",
        "candle holder", "candelabra", "oil lamp", "matchbox", "lighter", "flint",
        "anvil", "forge", "bellows", "horseshoe", "stirrup", "saddle", "bridle", "reins",
        "yoke", "plow", "scythe", "sickle", "combine", "hay bale", "grain silo",
        "windmill", "watermill", "water wheel", "dam", "lock gate", "canal boat",
        "rowboat", "speedboat", "yacht", "sailboat", "catamaran", "ferry", "cruise ship",
        "cargo ship", "submarine", "aircraft carrier", "battleship", "destroyer",
        "biplane", "jet", "helicopter", "glider", "hot air balloon", "blimp", "zeppelin",
        "drone", "rocket", "space shuttle", "satellite", "space station", "rover",
        "pickup truck", "semi truck", "fire truck", "ambulance", "police car", "taxi",
        "bus", "school bus", "trolley", "tram", "subway", "monorail", "cable car",
        "gondola", "ski lift", "snowmobile", "atv", "dirt bike", "moped", "segway",
        "unicycle", "tricycle", "wagon wheel", "cartwheel", "ferris wheel", "roller coaster",
        "carousel", "bumper car", "arcade cabinet", "pinball machine", "pool table",
        "foosball", "air hockey", "chessboard", "checkerboard", "jigsaw puzzle",
        "rubik cube", "playing cards", "poker chip", "dice", "spinner", "marble",
        "jump rope", "hula hoop", "frisbee", "boomerang", "slingshot", "bow and arrow",
        "crossbow", "cannon", "musket", "rifle", "pistol", "holster", "bullet", "shell",
        "helmet", "armor", "chainmail", "gauntlet", "greave", "shield", "banner",
        "flagpole", "weathervane", "lightning rod", "antenna", "satellite dish",
        "solar panel", "wind turbine", "power line", "transformer", "generator",
        "battery pack", "extension cord", "outlet", "switch", "dimmer", "thermostat",
        "radiator", "air conditioner", "ceiling fan", "desk lamp", "floor lamp",
        "night light", "string lights", "neon sign", "billboard", "marquee", "awning"
    ]

    space = [
        "moon", "sun", "star", "planet", "asteroid", "comet", "meteor", "meteorite",
        "galaxy", "nebula", "black hole", "supernova", "constellation", "orbit",
        "satellite", "space station", "space shuttle", "rocket", "astronaut", "telescope",
        "observatory", "crater", "eclipse", "lunar eclipse", "solar eclipse", "aurora",
        "northern lights", "milky way", "andromeda", "orion", "big dipper", "polaris",
        "sirius", "vega", "mercury", "venus", "earth", "mars", "jupiter", "saturn",
        "uranus", "neptune", "pluto", "ceres", "vesta", "io", "europa", "ganymede",
        "callisto", "titan", "enceladus", "triton", "charon", "phobos", "deimos",
        "halleys comet", "hale bopp", "shooting star", "fireball", "solar flare",
        "sunspot", "solar wind", "magnetosphere", "ozone", "atmosphere", "stratosphere",
        "iss", "hubble", "james webb", "voyager", "pioneer", "apollo", "saturn v",
        "space suit", "helmet visor", "airlock", "module", "capsule", "lander", "rover",
        "curiosity rover", "opportunity rover", "spirit rover", "sojourner", "perseverance",
        "ingenuity", "starlink", "gps satellite", "weather satellite", "hubble telescope",
        "radio telescope", "parallax", "light year", "asteroid belt", "kuiper belt",
        "oort cloud", "event horizon", "quasar", "pulsar", "white dwarf", "red giant",
        "brown dwarf", "neutron star", "dark matter", "cosmic dust", "solar system",
        "exoplanet", "earthrise", "full moon", "new moon", "crescent moon", "blue moon",
        "blood moon", "supermoon", "the moon", "the sun", "red planet", "the red planet",
        "planet mars", "planet jupiter", "planet saturn", "ringed planet"
    ]

    plants = [
        "tree", "oak", "maple", "pine", "cedar", "birch", "willow", "elm", "ash", "spruce",
        "fir", "redwood", "sequoia", "palm", "coconut palm", "date palm", "bamboo", "fern",
        "moss", "ivy", "vine", "grapevine", "rose", "tulip", "daisy", "sunflower", "lily",
        "orchid", "carnation", "daisy", "dandelion", "lavender", "lilac", "jasmine",
        "hibiscus", "poppy", "iris", "peony", "chrysanthemum", "marigold", "zinnia",
        "cactus", "succulent", "aloe", "agave", "yucca", "sagebrush", "tumbleweed",
        "wheat", "barley", "rye", "oats", "corn stalk", "sunflower field", "lavender field",
        "rice paddy", "vineyard", "orchard", "apple tree", "cherry blossom", "sakura",
        "bonsai", "topiary", "hedge", "shrub", "bush", "thicket", "forest", "jungle",
        "rainforest", "mangrove", "kelp", "seaweed", "coral", "lily pad", "lotus",
        "water lily", "reed", "cattail", "mushroom", "toadstool", "truffle", "morel",
        "pinecone", "acorn", "chestnut", "walnut tree", "olive tree", "fig tree",
        "banana tree", "orange tree", "lemon tree", "avocado tree", "cocoa tree",
        "coffee plant", "tea plant", "cotton plant", "tobacco leaf", "hemp", "flax",
        "daffodil", "hyacinth", "bluebell", "snowdrop", "crocus", "pansy", "violet",
        "forget me not", "buttercup", "clover", "shamrock", "thistle", "nettle",
        "poison ivy", "venus flytrap", "pitcher plant", "rafflesia", "baobab",
        "acacia", "eucalyptus", "baobab tree", "joshua tree", "saguaro", "prickly pear",
        "christmas tree", "wreath", "holly", "mistletoe", "poinsettia", "amaryllis"
    ]

    vehicles_places = [
        "airplane", "airport", "hangar", "runway", "control tower", "helicopter pad",
        "train station", "platform", "ticket booth", "turnstile", "subway car",
        "bus stop", "taxi stand", "garage", "parking lot", "gas station", "car wash",
        "mechanic shop", "dealership", "racetrack", "pit stop", "finish line",
        "harbor", "dock", "pier", "wharf", "lighthouse", "boathouse", "marina",
        "shipyard", "dry dock", "canal", "lock", "drawbridge", "overpass", "tunnel",
        "roundabout", "crosswalk", "stoplight", "billboard", "mile marker", "rest stop",
        "campground", "cabin", "lodge", "ranger station", "fire lookout", "trailhead",
        "switching yard", "grain elevator", "factory", "smokestack", "water tower",
        "silo", "barn", "stable", "henhouse", "windmill", "farmhouse", "porch",
        "gazebo", "pergola", "trellis", "greenhouse", "toolshed", "woodshed",
        "playground", "sandbox", "swing set", "slide", "jungle gym", "see saw",
        "merry go round", "sprinkler", "hydrant", "manhole", "storm drain",
        "courthouse", "city hall", "library", "museum", "gallery", "theater",
        "opera house", "concert hall", "stadium", "arena", "ballpark", "bleachers",
        "scoreboard", "dugout", "locker room", "gymnasium", "pool", "diving board",
        "hot tub", "sauna", "ice rink", "ski slope", "chairlift", "lodge", "chalet",
        "igloo", "yurt", "teepee", "tent", "camper", "rv", "houseboat", "treehouse"
    ]

    instruments_sports = [
        "soccer ball", "football", "basketball", "baseball", "softball", "volleyball",
        "tennis ball", "golf ball", "bowling ball", "billiard ball", "hockey puck",
        "hockey stick", "baseball bat", "cricket bat", "tennis racket", "badminton racket",
        "golf club", "putter", "driver", "lacrosse stick", "polo mallet", "croquet mallet",
        "ping pong paddle", "shuttlecock", "frisbee", "boomerang", "lawn dart",
        "goal post", "net", "backboard", "hoop", "home plate", "pitchers mound",
        "boxing glove", "punching bag", "mouthguard", "shin guard", "knee pad",
        "helmet", "facemask", "cleat", "skate", "figure skate", "ice skate", "rollerblade",
        "surfboard", "bodyboard", "paddleboard", "kayak paddle", "life vest",
        "snorkel", "scuba tank", "flipper", "wetsuit", "goggles", "stopwatch",
        "whistle", "starting block", "hurdle", "javelin", "discus", "shot put",
        "pole vault", "high jump bar", "balance beam", "uneven bars", "pommel horse",
        "rings", "vault", "yoga mat", "dumbbell", "barbell", "kettlebell", "weight plate",
        "treadmill", "stationary bike", "row machine", "jump rope", "resistance band"
    ]

    clothing = [
        "hat", "cap", "beanie", "beret", "fedora", "cowboy hat", "top hat", "sombrero",
        "helmet", "crown", "tiara", "veil", "scarf", "shawl", "poncho", "cloak", "cape",
        "coat", "jacket", "parka", "raincoat", "trench coat", "blazer", "vest", "sweater",
        "hoodie", "cardigan", "shirt", "t shirt", "polo", "blouse", "dress", "gown",
        "skirt", "kilt", "pants", "jeans", "shorts", "leggings", "tights", "socks",
        "stockings", "boots", "shoes", "sneakers", "sandals", "flip flops", "heels",
        "loafers", "moccasins", "clogs", "slippers", "ice skates", "snowshoes",
        "gloves", "mittens", "muff", "belt", "suspenders", "tie", "bow tie", "cravat",
        "necklace", "bracelet", "ring", "earring", "brooch", "watch", "pocket watch",
        "glasses", "sunglasses", "monocle", "goggles", "mask", "eyepatch", "wig",
        "backpack", "purse", "handbag", "clutch", "wallet", "umbrella", "cane", "staff",
        "kimono", "yukata", "hanbok", "sari", "turban", "keffiyeh", "fez", "ushanka",
        "armor", "breastplate", "chainmail", "gauntlet", "tunic", "robe", "toga",
        "superhero cape", "wizard hat", "witch hat", "santa hat", "elf shoes"
    ]

    nature = [
        "mountain", "hill", "valley", "canyon", "gorge", "cliff", "bluff", "mesa", "butte",
        "plateau", "plain", "prairie", "steppe", "tundra", "desert", "dune", "oasis",
        "beach", "shore", "coast", "cove", "bay", "inlet", "fjord", "peninsula", "island",
        "archipelago", "atoll", "reef", "lagoon", "lake", "pond", "pool", "spring",
        "river", "stream", "creek", "brook", "waterfall", "cascade", "rapids", "whirlpool",
        "glacier", "iceberg", "ice sheet", "snowfield", "avalanche", "crevasse",
        "volcano", "crater", "caldera", "lava", "magma", "geyser", "hot spring", "fumarole",
        "cave", "cavern", "grotto", "stalactite", "stalagmite", "sinkhole", "canyon wall",
        "cloud", "cumulus", "thunderhead", "rainbow", "double rainbow", "lightning",
        "thunder", "storm", "tornado", "hurricane", "cyclone", "typhoon", "blizzard",
        "snowflake", "icicle", "frost", "dew", "mist", "fog", "haze", "smog", "sunset",
        "sunrise", "horizon", "skyline", "starry sky", "milky way", "aurora",
        "pebble", "stone", "boulder", "rock", "crystal", "geode", "gem", "diamond",
        "ruby", "emerald", "sapphire", "opal", "amber", "pearl", "gold nugget", "silver",
        "fossil", "amber fossil", "shell", "conch", "sand dollar", "coral reef",
        "tide pool", "wave", "whitecap", "surf", "ripple", "reflection"
    ]

    names_titles = [
        "big ben", "lady liberty", "old faithful", "half dome", "el capitan", "uluru",
        "ayers rock", "matterhorn", "mont blanc", "k2", "annapurna", "everest",
        "kilimanjaro", "denali", "rainier", "shasta", "hood", "baker", "olympus",
        "vesuvius", "etna", "stromboli", "krakatoa", "st helens", "fuji", "mt fuji",
        "mt. fuji", "fuji mountain", "olympus mons", "mare tranquillitatis",
        "sea of tranquility", "copernicus crater", "tycho crater", "valles marineris",
        "olympus mons", "great red spot", "rings of saturn", "tour eiffel",
        "the eiffel tower", "eiffel", "statue of liberty", "liberty", "lady liberty",
        "golden gate bridge", "the golden gate", "brooklyn bridge", "tower bridge",
        "harbour bridge", "sydney harbour", "opera house", "colosseum", "coliseum",
        "leaning tower", "pisa", "sagrada familia", "gaudi church", "neuschwanstein castle",
        "hogwarts", "camelot", "avalon", "atlantis", "el dorado", "shangri la",
        "narnia wardrobe", "yellow brick road", "emerald city", "beanstalk",
        "trojan horse", "excalibur", "holy grail", "ark", "noahs ark", "sphinx",
        "roses", "tulips", "daisies"
    ]

    extra = [
        "paris", "london", "rome", "venice", "florence", "barcelona", "madrid", "lisbon",
        "athens", "istanbul", "cairo", "dubai", "mumbai", "delhi", "bangkok", "tokyo",
        "kyoto", "osaka", "seoul", "beijing", "shanghai", "hong kong", "singapore",
        "sydney", "melbourne", "auckland", "wellington", "rio de janeiro", "buenos aires",
        "lima", "cusco", "bogota", "mexico city", "havana", "kingston", "new york",
        "boston", "chicago", "seattle", "portland", "denver", "austin", "dallas", "houston",
        "miami", "atlanta", "nashville", "new orleans", "san francisco", "los angeles",
        "san diego", "las vegas", "phoenix", "honolulu", "anchorage", "vancouver",
        "toronto", "montreal", "quebec city", "ottawa", "calgary", "edmonton",
        "ireland", "scotland", "wales", "england", "france", "italy", "spain", "portugal",
        "germany", "netherlands", "belgium", "switzerland", "austria", "sweden", "norway",
        "denmark", "finland", "iceland", "greece", "turkey", "egypt", "morocco", "kenya",
        "tanzania", "south africa", "india", "nepal", "china", "japan", "korea", "thailand",
        "vietnam", "indonesia", "australia", "new zealand", "brazil", "peru", "chile",
        "argentina", "canada", "mexico", "cuba", "jamaica", "hawaii", "alaska",
        "spatula", "whisk", "ladle", "colander", "grater", "peeler", "can opener",
        "corkscrew", "bottle opener", "rolling pin", "cutting board", "mixing bowl",
        "measuring cup", "timer", "oven mitt", "pot holder", "apron", "recipe book",
        "slow cooker", "instant pot", "air fryer", "rice cooker", "toaster oven",
        "waffle iron", "sandwich press", "coffee maker", "espresso machine", "french press",
        "kettle", "tea kettle", "thermos", "water bottle", "pitcher", "carafe", "decanter",
        "wine glass", "beer mug", "shot glass", "martini glass", "champagne flute",
        "coffee mug", "travel mug", "sippy cup", "baby bottle", "straw", "napkin",
        "placemat", "tablecloth", "centerpiece", "candlestick", "votive", "tea light",
        "soap dish", "toothbrush holder", "toothpaste", "floss", "mouthwash", "razor",
        "shaving cream", "hairbrush", "comb", "hair dryer", "curling iron", "straightner",
        "mirror", "medicine cabinet", "towel rack", "bath towel", "washcloth", "loofah",
        "showerhead", "bathtub", "shower curtain", "bathmat", "scale", "plunger",
        "toilet paper", "tissue box", "trash can", "recycling bin", "laundry basket",
        "hamper", "clothespin", "iron board", "sewing kit", "thread", "button", "zipper",
        "safety pin", "needle", "thimble", "measuring tape", "yardstick", "level",
        "stud finder", "utility knife", "box cutter", "duct tape", "masking tape",
        "packing tape", "glue stick", "super glue", "wood glue", "hot glue gun",
        "paint roller", "paint tray", "drop cloth", "stepladder", "extension ladder",
        "sawhorse", "workbench", "vise", "clamp", "c-clamp", "pipe wrench", "allen key",
        "socket wrench", "torque wrench", "hex key", "phillips screwdriver",
        "flathead screwdriver", "needle nose", "wire cutter", "hacksaw", "circular saw",
        "jigsaw", "miter saw", "table saw", "router", "sander", "orbital sander",
        "paint sprayer", "pressure washer", "leaf blower", "hedge trimmer", "chainsaw",
        "snowblower", "generator", "jumper cables", "car jack", "spare tire", "hubcap",
        "steering wheel", "dashboard", "speedometer", "rearview mirror", "headlight",
        "taillight", "license plate", "windshield", "wiper blade", "antenna",
        "shopping cart", "basket", "cash register", "barcode scanner", "price tag",
        "mannequin", "hanger", "fitting room", "escalator", "elevator", "revolving door",
        "doormat", "welcome mat", "doorbell", "peep hole", "deadbolt", "chain lock",
        "window pane", "shutters", "blinds", "curtains", "drapes", "valance",
        "ceiling fan", "smoke detector", "carbon monoxide detector", "thermostat",
        "light switch", "dimmer switch", "outlet", "power strip", "surge protector",
        "extension cord", "usb cable", "charging brick", "power bank", "dongle",
        "hdmi cable", "router", "modem", "wifi router", "ethernet cable", "server",
        "hard drive", "flash drive", "sd card", "memory card", "cd", "dvd", "blu ray",
        "vinyl record", "cassette tape", "vhs tape", "floppy disk", "zip disk",
        "typewriter", "adding machine", "cash box", "safe", "lockbox", "piggy bank",
        "coin jar", "wallet", "billfold", "money clip", "credit card", "gift card",
        "passport", "boarding pass", "luggage tag", "suitcase", "carry on", "duffel",
        "weekender", "backpack", "messenger bag", "tote bag", "fanny pack", "belt bag",
        "camera bag", "lens cap", "camera strap", "memory card slot", "flash",
        "softbox", "reflector", "backdrop", "boom stand", "gimbal", "drone controller",
        "action camera", "gopro", "webcam", "ring light", "selfie stick", "tripod",
        "monopod", "slider", "dolly", "crane", "jib", "green screen", "clapperboard",
        "megaphone", "walkie talkie", "ham radio", "cb radio", "police scanner",
        "weather radio", "boombox", "stereo", "receiver", "amplifier", "equalizer",
        "subwoofer", "soundbar", "turntable", "mixer", "microphone stand", "pop filter",
        "music stand", "metronome", "tuning fork", "capo", "guitar pick", "guitar strap",
        "violin bow", "rosin", "reed", "mouthpiece", "drumstick", "cymbal stand",
        "hi hat", "snare drum", "bass drum", "tom tom", "cowbell", "woodblock",
        "kazoo", "harmonica", "melodica", "recorder", "ocarina", "pan flute",
        "didgeridoo", "sitar", "koto", "erhu", "tabla", "djembe", "bongo", "conga",
        "steel drum", "marimba", "vibraphone", "glockenspiel", "triangle", "gong",
        "church bell", "handbell", "wind chime", "music box", "player piano",
        "grand piano", "upright piano", "organ", "pipe organ", "harpsichord",
        "clavichord", "accordion", "concertina", "hurdy gurdy", "lyre", "lute", "harp",
        "teddy bear", "rag doll", "action figure", "toy soldier", "toy car", "toy train",
        "remote car", "rc helicopter", "kaleidoscope", "viewmaster", "etch a sketch",
        "magic eight ball", "snow globe", "music box", "jack in the box", "nesting dolls",
        "yo yo", "slinky", "pogo stick", "stilts", "unicycle", "hobby horse",
        "rocking horse", "dollhouse", "toy kitchen", "toy workbench", "legos",
        "building blocks", "wooden blocks", "train set", "marble run", "jigsaw",
        "crossword", "sudoku", "scrabble", "monopoly", "chess", "checkers", "backgammon",
        "go board", "mahjong", "dominoes", "playing cards", "uno", "jenga", "connect four",
        "operation", "battleship", "clue", "risk", "settlers", "ticket to ride",
        "fire pit", "grill", "smoker", "pizza oven", "chiminea", "patio heater",
        "string lights", "tiki torch", "citronella candle", "bug zapper", "hammock",
        "porch swing", "adirondack chair", "lounge chair", "chaise", "umbrella stand",
        "birdbath", "bird feeder", "birdhouse", "squirrel feeder", "doghouse", "dog bed",
        "cat tree", "litter box", "fish tank", "aquarium", "goldfish bowl", "terrarium",
        "ant farm", "hamster wheel", "guinea pig cage", "birdcage", "perch", "cuttlebone",
        "saddle", "horseshoe", "hay net", "water trough", "fence post", "barbed wire",
        "gate", "stile", "cattle grid", "scarecrow", "weathervane", "lightning rod",
        "mailbox", "newspaper box", "flagpole", "windsock", "weather station",
        "barometer", "thermometer", "hygrometer", "rain gauge", "anemometer",
        "compass", "sextant", "binoculars", "spotting scope", "rangefinder",
        "walkie talkie", "flare gun", "life raft", "life jacket", "life ring",
        "anchor", "chain", "cleat", "bollard", "gangway", "porthole", "crow nest",
        "ship wheel", "rudder", "keel", "mast", "boom", "sail", "spinnaker", "jib",
        "rigging", "winch", "capstan", "bell", "foghorn", "lighthouse lamp",
        "buoy", "channel marker", "dayboard", "harbor light"
    ]

    return (
        animals + foods + landmarks + objects + space + plants
        + vehicles_places + instruments_sports + clothing + nature + names_titles
        + extra
    )


def main() -> None:
    words = unique_keep_order(puzzle_answers() + dictionary())
    OUT.write_text(json.dumps(words, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {len(words)} words to {OUT}")


if __name__ == "__main__":
    main()
