import Curry
import Prelude
import ReactiveSwift
import Runes

public struct Project {
  public var availableCardTypes: [String]?
  public var blurb: String
  public var category: Category
  public var country: Country
  public var creator: User
  public var memberData: MemberData
  public var dates: Dates
  public var id: Int
  public var location: Location
  public var name: String
  public var personalization: Personalization
  public var photo: Photo
  public var prelaunchActivated: Bool?
  public var rewardData: RewardData
  public var slug: String
  public var staffPick: Bool
  public var state: State
  public var stats: Stats
  public var urls: UrlsEnvelope
  public var video: Video?

  public struct Category {
    public var id: Int
    public var name: String
    public var parentId: Int?
    public var parentName: String?

    public var rootId: Int {
      return self.parentId ?? self.id
    }
  }

  public struct UrlsEnvelope {
    public var web: WebEnvelope

    public struct WebEnvelope {
      public var project: String
      public var updates: String?
    }
  }

  public struct Video {
    public var id: Int
    public var high: String
    public var hls: String?
  }

public enum State: String, Decodable, CaseIterable, Swift.Decodable {
    case canceled
    case failed
    case live
    case purged
    case started
    case submitted
    case successful
    case suspended
  }

  public struct Stats {
    public var backersCount: Int
    public var commentsCount: Int?
    public var convertedPledgedAmount: Int?
    /// The currency code of the project ex. USD
    public var currency: String
    /// The currency code of the User's preferred currency ex. SEK
    public var currentCurrency: String?
    /// The currency conversion rate between the User's preferred currency
    /// and the Project's currency
    public var currentCurrencyRate: Float?
    public var goal: Int
    public var pledged: Int
    public var staticUsdRate: Float
    public var updatesCount: Int?

    /// Percent funded as measured from `0.0` to `1.0`. See `percentFunded` for a value from `0` to `100`.
    public var fundingProgress: Float {
      return self.goal == 0 ? 0.0 : Float(self.pledged) / Float(self.goal)
    }

    /// Percent funded as measured from `0` to `100`. See `fundingProgress` for a value between `0.0`
    /// and `1.0`.
    public var percentFunded: Int {
      return Int(floor(self.fundingProgress * 100.0))
    }

    /// Pledged amount converted to USD.
    public var pledgedUsd: Int {
      return Int(floor(Float(self.pledged) * self.staticUsdRate))
    }

    /// Goal amount converted to USD.
    public var goalUsd: Int {
      return Int(floor(Float(self.goal) * self.staticUsdRate))
    }

    /// Goal amount converted to current currency.
    public var goalCurrentCurrency: Int? {
      return self.currentCurrencyRate.map { Int(floor(Float(self.goal) * $0)) }
    }

    /// Country determined by current currency.
    public var currentCountry: Project.Country? {
      guard let currentCurrency = self.currentCurrency else {
        return nil
      }

      return Project.Country(currencyCode: currentCurrency)
    }

    /// Omit US currency code
    public var omitUSCurrencyCode: Bool {
      let currentCurrency = self.currentCurrency ?? Project.Country.us.currencyCode

      return currentCurrency == Project.Country.us.currencyCode
    }

    /// Project pledge & goal values need conversion
    public var needsConversion: Bool {
      let currentCurrency = self.currentCurrency ?? Project.Country.us.currencyCode

      return self.currency != currentCurrency
    }

    public var goalMet: Bool {
      return self.pledged >= self.goal
    }
  }

  public struct MemberData {
    public var lastUpdatePublishedAt: TimeInterval?
    public var permissions: [Permission]
    public var unreadMessagesCount: Int?
    public var unseenActivityCount: Int?

    public enum Permission: String {
      case editProject = "edit_project"
      case editFaq = "edit_faq"
      case post
      case comment
      case viewPledges = "view_pledges"
      case fulfillment
      case unknown
    }
  }

  public struct Dates {
    public var deadline: TimeInterval
    public var featuredAt: TimeInterval?
    public var finalCollectionDate: TimeInterval?
    public var launchedAt: TimeInterval
    public var stateChangedAt: TimeInterval

    /**
     Returns project duration in Days
     */
    public func duration(using calendar: Calendar = .current) -> Int? {
      let deadlineDate = Date(timeIntervalSince1970: self.deadline)
      let launchedAtDate = Date(timeIntervalSince1970: self.launchedAt)

      return calendar.dateComponents([.day], from: launchedAtDate, to: deadlineDate).day
    }

    public func hoursRemaining(from date: Date = Date(), using calendar: Calendar = .current) -> Int? {
      let deadlineDate = Date(timeIntervalSince1970: self.deadline)

      guard let hoursRemaining = calendar.dateComponents([.hour], from: date, to: deadlineDate).hour else {
        return nil
      }

      return max(0, hoursRemaining)
    }
  }

  public struct Personalization {
    public var backing: Backing?
    public var friends: [User]?
    public var isBacking: Bool?
    public var isStarred: Bool?
  }

  public struct Photo {
    public var full: String
    public var med: String
    public var size1024x768: String?
    public var small: String
  }

  public struct RewardData {
    public var addOns: [Reward]?
    public var rewards: [Reward]
  }

  public var hasAddOns: Bool {
    return self.addOns?.isEmpty == false
  }

  public var addOns: [Reward]? {
    return self.rewardData.addOns
  }

  public var rewards: [Reward] {
    return self.rewardData.rewards
  }

  public func endsIn48Hours(today: Date = Date()) -> Bool {
    let twoDays: TimeInterval = 60.0 * 60.0 * 48.0
    return self.dates.deadline - today.timeIntervalSince1970 <= twoDays
  }

  public func isFeaturedToday(today: Date = Date(), calendar: Calendar = .current) -> Bool {
    guard let featuredAt = self.dates.featuredAt else { return false }
    return self.isDateToday(date: featuredAt, today: today, calendar: calendar)
  }

  private func isDateToday(date: TimeInterval, today: Date, calendar: Calendar) -> Bool {
    let startOfToday = calendar.startOfDay(for: today)
    return abs(startOfToday.timeIntervalSince1970 - date) < 60.0 * 60.0 * 24.0
  }
}

extension Project: Equatable {}
public func == (lhs: Project, rhs: Project) -> Bool {
  return lhs.id == rhs.id
}

extension Project: CustomDebugStringConvertible {
  public var debugDescription: String {
    return "Project(id: \(self.id), name: \"\(self.name)\")"
  }
}

extension Project: Swift.Decodable {
  enum CodingKeys: String, CodingKey {
    case availableCardTypes = "available_card_types"
    case blurb = "blurb"
    case category = "category"
    case country
    case creator = "creator"
    case memberData
    case dates
    case id = "id"
    case location = "location"
    case name = "name"
    case personalization
    case photo = "photo"
    case prelaunchActivated = "prelaunch_activated"
    case rewardData
    case slug = "slug"
    case staffPick = "staffPick"
    case state = "state"
    case stats
    case urls = "urls"
    case video = "video"
    //TODO finish mapping flat str
  }
}
/*
extension Project: Decodable {
  public static func decode(_ json: JSON) -> Decoded<Project> {
    let tmp1 = curry(Project.init)
      <^> json <||? "available_card_types"
      <*> json <| "blurb"
      <*> json <| "category"
      <*> Project.Country.decode(json)
      <*> json <| "creator"
    let tmp2 = tmp1
      <*> Project.MemberData.decode(json)
      <*> Project.Dates.decode(json)
      <*> json <| "id"
      <*> (json <| "location" <|> .success(Location.none))
    let tmp3 = tmp2
      <*> json <| "name"
      <*> Project.Personalization.decode(json)
      <*> json <| "photo"
      <*> json <|? "prelaunch_activated"
      <*> Project.RewardData.decode(json)
      <*> json <| "slug"
    return tmp3
      <*> json <| "staff_pick"
      <*> json <| "state"
      <*> Project.Stats.decode(json)
      <*> json <| "urls"
      <*> json <|? "video"
  }
}
*/
extension Project.UrlsEnvelope: Swift.Decodable {
  enum CodingKeys: String, CodingKey {
    case web = "web"
  }
}

extension Project.UrlsEnvelope.WebEnvelope: Swift.Decodable {
  enum CodingKeys: String, CodingKey {
    case project = "project"
    case updates = "updates"
  }
}

extension Project.UrlsEnvelope: Decodable {
  public static func decode(_ json: JSON) -> Decoded<Project.UrlsEnvelope> {
    return curry(Project.UrlsEnvelope.init)
      <^> json <| "web"
  }
}

extension Project.UrlsEnvelope.WebEnvelope: Decodable {
  public static func decode(_ json: JSON) -> Decoded<Project.UrlsEnvelope.WebEnvelope> {
    return curry(Project.UrlsEnvelope.WebEnvelope.init)
      <^> json <| "project"
      <*> json <|? "updates"
  }
}

extension Project.Stats: Swift.Decodable {
  enum CodingKeys: String, CodingKey {
    case backersCount = "backers_count"
    case commentsCount = "comments_count"
    case convertedPledgedAmount = "converted_pledged_amount"
    case currency = "currency"
    case currentCurrency = "current_currency"
    case currentCurrencyRate = "fx_rate"
    case goal = "goal"
    case pledged = "pledged"
    case staticUsdRate = "static_usd_rate"
    case updatesCount = "updates_count"
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    self.backersCount = try values.decode(Int.self, forKey: .backersCount)
    self.commentsCount = try values.decodeIfPresent(Int.self, forKey: .commentsCount)
    self.convertedPledgedAmount = try values.decodeIfPresent(Int.self, forKey: .convertedPledgedAmount)
    self.currency = try values.decode(String.self, forKey: .currency)
    self.currentCurrency = try values.decodeIfPresent(String.self, forKey: .currentCurrency)
    self.currentCurrencyRate = try values.decodeIfPresent(Float.self, forKey: .currentCurrencyRate)
    self.goal = try values.decode(Int.self, forKey: .goal)
    self.pledged = try values.decode(Int.self, forKey: .pledged)
    self.staticUsdRate = try values.decodeIfPresent(Float.self, forKey: .staticUsdRate) ?? 1.0
    self.updatesCount = try values.decodeIfPresent(Int.self, forKey: .updatesCount)
  }

}


extension Project.Stats: Decodable {
  public static func decode(_ json: JSON) -> Decoded<Project.Stats> {
    let tmp1 = curry(Project.Stats.init)
      <^> json <| "backers_count"
      <*> json <|? "comments_count"
      <*> json <|? "converted_pledged_amount"
      <*> json <| "currency"
      <*> json <|? "current_currency"
      <*> json <|? "fx_rate"
    return tmp1
      <*> json <| "goal"
      <*> json <| "pledged"
      <*> (json <| "static_usd_rate" <|> .success(1.0))
      <*> json <|? "updates_count"
  }
}

extension Project.MemberData: Swift.Decodable {
  enum CodingKeys: String, CodingKey {
    case lastUpdatePublishedAt = "last_update_published_at"
    case permissions = "permissions"
    case unreadMessagesCount = "unread_messages_count"
    case unseenActivityCount = "unseen_activity_count"
  }
}

extension Project.MemberData: Decodable {
  public static func decode(_ json: JSON) -> Decoded<Project.MemberData> {
    return curry(Project.MemberData.init)
      <^> json <|? "last_update_published_at"
      <*> (removeUnknowns <^> (json <|| "permissions") <|> .success([]))
      <*> json <|? "unread_messages_count"
      <*> json <|? "unseen_activity_count"
  }
}

extension Project.Dates: Swift.Decodable {
  enum CodingKeys: String, CodingKey {
    case deadline = "deadline"
    case featuredAt = "featured_at"
    case finalCollectionDate = "final_collection_date"
    case launchedAt = "launched_at"
    case stateChangedAt = "state_changed_at"
  }
}

extension Project.Dates: Decodable {
  public static func decode(_ json: JSON) -> Decoded<Project.Dates> {
    return curry(Project.Dates.init)
      <^> json <| "deadline"
      <*> json <|? "featured_at"
      <*> json <|? "final_collection_date"
      <*> json <| "launched_at"
      <*> json <| "state_changed_at"
  }
}

extension Project.Personalization: Swift.Decodable {
  enum CodingKeys: String, CodingKey {
    case backing = "backing"
    case friends = "friends"
    case isBacking = "is_backing"
    case isStarred = "is_starred"
  }
}

/*
extension Project.Personalization: Decodable {
  public static func decode(_ json: JSON) -> Decoded<Project.Personalization> {
    return curry(Project.Personalization.init)
      <^> json <|? "backing"
      <*> json <||? "friends"
      <*> json <|? "is_backing"
      <*> json <|? "is_starred"
  }
}
*/
extension Project.RewardData: Swift.Decodable {
  enum CodingKeys: String, CodingKey {
    case addOns = "add_ons"
    case rewards = "rewards"
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    self.addOns = try values.decodeIfPresent([Reward].self, forKey: .addOns)
    self.rewards = try values.decodeIfPresent([Reward].self, forKey: .addOns) ?? []
  }
}

extension Project.RewardData: Decodable {
  public static func decode(_ json: JSON) -> Decoded<Project.RewardData> {
    return curry(Project.RewardData.init)
      <^> json <||? "add_ons"
      <*> (json <|| "rewards" <|> .success([]))
  }
}

extension Project.Category: Swift.Decodable {
  enum CodingKeys: String, CodingKey {
    case id = "id"
    case name = "name"
    case parentId = "parent_id"
    case parentName = "parent_name"
  }
}

extension Project.Category: Decodable {
  public static func decode(_ json: JSON) -> Decoded<Project.Category> {
    return curry(Project.Category.init)
      <^> json <| "id"
      <*> json <| "name"
      <*> json <|? "parent_id"
      <*> json <|? "parent_name"
  }
}

extension Project.Photo: Swift.Decodable {
  enum CodingKeys: String, CodingKey {
    case full = "full"
    case med = "med"
    case size1024x768 = "1024x768"
    case size1024x576 = "1024x576"
    case small = "small"
  }


  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    self.full = try values.decode(String.self, forKey: .full)
    self.med = try values.decode(String.self, forKey: .med)
    //TODO - fix type
    self.size1024x768 = try values.decodeIfPresent(String.self, forKey: .size1024x768) ?? (try values.decodeIfPresent(String.self, forKey: .size1024x576))
    self.small = try values.decode(String.self, forKey: .small)
  }
}

extension Project.Photo: Decodable {
  public static func decode(_ json: JSON) -> Decoded<Project.Photo> {
    let url1024: Decoded<String?> = ((json <| "1024x768") <|> (json <| "1024x576"))
      .map(Optional<String>.init)
      <|> .success(nil)

    return curry(Project.Photo.init)
      <^> json <| "full"
      <*> json <| "med"
      <*> url1024
      <*> json <| "small"
  }
}

extension Project.MemberData.Permission: Swift.Decodable {
  
  public init(from decoder: Decoder) throws {
    self = try Project.MemberData.Permission(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
  }
  
}

extension Project.MemberData.Permission: Decodable {
  public static func decode(_ json: JSON) -> Decoded<Project.MemberData.Permission> {
    if case let .string(permission) = json {
      return self.init(rawValue: permission).map(pure) ?? .success(.unknown)
    }
    return .success(.unknown)
  }
}

private func removeUnknowns(_ xs: [Project.MemberData.Permission]) -> [Project.MemberData.Permission] {
  return xs.filter { $0 != .unknown }
}

private func toInt(string: String) -> Decoded<Int> {
  return Int(string).map(Decoded.success)
    ?? Decoded.failure(DecodeError.custom("Couldn't decoded \"\(string)\" into Int."))
}

extension Project: GraphIDBridging {
  public static var modelName: String {
    return "Project"
  }
}

// MARK: - GraphQL Adapters

extension Project {
  static func projectProducer(
    from envelope: RewardAddOnSelectionViewEnvelope
  ) -> SignalProducer<Project, ErrorEnvelope> {
    guard let project = Project.project(from: envelope.project) else {
      return SignalProducer(error: .couldNotParseJSON)
    }

    return SignalProducer(value: project)
  }
}

extension Project.Video: Swift.Decodable {}
