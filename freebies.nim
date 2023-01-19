import httpclient, json, os, parseopt, strscans, strformat, strutils, times

const EPIC_DB = "https://store-site-backend-static.ak.epicgames.com/freeGamesPromotions?country=US"
const EPIC_URL = "https://store.epicgames.com/en-US/p/"
const UTC_NOTIFY_TIME = 18
const NTFY_SERVER = "ntfy.sh"
const NTFY_TOPIC = "giveaways"

type GameData = tuple
    name, url: string

type Date = tuple
    month, day, year: int

proc getDate(): Date =
    let datetime = now().utc()
    result.month = int(datetime.month)
    result.day = int(datetime.monthday)
    result.year = datetime.year

proc getGames(): seq[GameData] =
    var client = newHttpClient()
    let raw = client.getContent(EPIC_DB)
    let data = parseJson(raw)
    let games = data["data"]["Catalog"]["searchStore"]["elements"]
    for game in games:
        let name = game["title"].getStr()
        var url = game["productSlug"].getStr()

        if url == "" and len(game["catalogNs"]["mappings"]) > 0:
            url = game["catalogNs"]["mappings"][0]["pageSlug"].getStr()

        if url == "":
            continue

        url.removeSuffix("/home")

        let discount_price = game["price"]["totalPrice"]["discountPrice"]
        if discount_price.getInt() != 0:
            # Not free
            continue

        let original_price = game["price"]["totalPrice"]["originalPrice"]
        if original_price.getInt() == 0:
            # Always free
            continue

        if game["offerType"].getStr() != "BASE_GAME":
            continue

        let start_date = game["promotions"]["promotionalOffers"][0]["promotionalOffers"][0]["startDate"].getStr()
        let (success, year, month, day) = start_date.scanTuple("$i-$i-$iT")
        if not success:
            continue

        let freedate = (month, day, year)
        if freedate != getDate():
            continue

        result.add((name, EPIC_URL & url))

proc sendNotification(games: seq[GameData]) =
    var client = newHttpClient()
    for game in games:
        let body = &"New free Epic game:\n{game.name}\n{game.url}"
        echo(body)
        discard client.postContent(NTFY_SERVER & NTFY_TOPIC, body = body)
        sleep(1000)

proc sleepUntilTime() =
    let today_date = getDate()
    let current = now().utc()
    let today = dateTime(today_date.year, cast[Month](today_date.month), today_date.day, hour = UTC_NOTIFY_TIME, zone = utc())
    let tomorrow = dateTime(today_date.year, cast[Month](today_date.month), today_date.day + 1, hour = UTC_NOTIFY_TIME, zone = utc())
    if today > current:
        let dt = today - current
        sleep(int(dt.inMilliseconds()))
    else:
        let dt = tomorrow - current
        sleep(int(dt.inMilliseconds()))

proc check() =
    let games = getGames()
    if games.len() > 0:
        sendNotification(games)

proc loopForever() =
    while true:
        sleepUntilTime()
        check()

proc main() =
    var opts = initOptParser()
    var cron_mode = false

    for kind, key, val in opts.getopt():
        if kind == cmdShortOption and key == "c":
            cron_mode = true

    if cron_mode:
        check()
    else:
        loopForever()

when isMainModule:
    main()

