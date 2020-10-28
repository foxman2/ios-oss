import Foundation
import Prelude
import ReactiveExtensions
import ReactiveSwift

public extension Bundle {
  var _buildVersion: String {
    return (self.infoDictionary?["CFBundleVersion"] as? String) ?? "1"
  }
}

/**
 A `ServerType` that requests data from an API webservice.
 */
public struct Service: ServiceType {
  public let appId: String
  public let serverConfig: ServerConfigType
  public let oauthToken: OauthTokenAuthType?
  public let language: String
  public let currency: String
  public let buildVersion: String
  public let deviceIdentifier: String

  public init(
    appId: String = Bundle.main.bundleIdentifier ?? "com.kickstarter.kickstarter",
    serverConfig: ServerConfigType = ServerConfig.production,
    oauthToken: OauthTokenAuthType? = nil,
    language: String = "en",
    currency: String = "USD",
    buildVersion: String = Bundle.main._buildVersion,
    deviceIdentifier: String = UIDevice.current.identifierForVendor.coalesceWith(UUID()).uuidString
  ) {
    self.appId = appId
    self.serverConfig = serverConfig
    self.oauthToken = oauthToken
    self.language = language
    self.currency = currency
    self.buildVersion = buildVersion
    self.deviceIdentifier = deviceIdentifier

    // Global override required for injecting custom User-Agent header in ajax requests
    UserDefaults.standard.register(defaults: ["UserAgent": Service.userAgent])
  }

  public func login(_ oauthToken: OauthTokenAuthType) -> Service {
    return Service(
      appId: self.appId,
      serverConfig: self.serverConfig,
      oauthToken: oauthToken,
      language: self.language,
      buildVersion: self.buildVersion
    )
  }

  public func logout() -> Service {
    return Service(
      appId: self.appId,
      serverConfig: self.serverConfig,
      oauthToken: nil,
      language: self.language,
      buildVersion: self.buildVersion
    )
  }

  public func facebookConnect(facebookAccessToken token: String) -> SignalProducer<User, ErrorEnvelope> {
    return requestDecodable(.facebookConnect(facebookAccessToken: token))
  }

  public func addImage(file fileURL: URL, toDraft draft: UpdateDraft)
    -> SignalProducer<UpdateDraft.Image, ErrorEnvelope> {
    return requestDecodable(Route.addImage(fileUrl: fileURL, toDraft: draft))
  }

  public func addNewCreditCard(input: CreatePaymentSourceInput)
    -> SignalProducer<CreatePaymentSourceEnvelope, GraphError> {
    return applyMutation(mutation: CreatePaymentSourceMutation(input: input))
  }

  public func addVideo(file fileURL: URL, toDraft draft: UpdateDraft)
    -> SignalProducer<UpdateDraft.Video, ErrorEnvelope> {
    return requestDecodable(Route.addVideo(fileUrl: fileURL, toDraft: draft))
  }

  public func cancelBacking(input: CancelBackingInput)
    -> SignalProducer<GraphMutationEmptyResponseEnvelope, GraphError> {
    return applyMutation(mutation: CancelBackingMutation(input: input))
  }

  public func changeEmail(input: ChangeEmailInput) ->
    SignalProducer<GraphMutationEmptyResponseEnvelope, GraphError> {
    return applyMutation(mutation: UpdateUserAccountMutation(input: input))
  }

  public func changePassword(input: ChangePasswordInput) ->
    SignalProducer<GraphMutationEmptyResponseEnvelope, GraphError> {
    return applyMutation(mutation: UpdateUserAccountMutation(input: input))
  }

  public func createBacking(input: CreateBackingInput) ->
    SignalProducer<CreateBackingEnvelope, GraphError> {
    return applyMutation(mutation: CreateBackingMutation(input: input))
  }

  public func createPassword(input: CreatePasswordInput) ->
    SignalProducer<GraphMutationEmptyResponseEnvelope, GraphError> {
    return applyMutation(mutation: UpdateUserAccountMutation(input: input))
  }

  public func changePaymentMethod(project: Project)
    -> SignalProducer<ChangePaymentMethodEnvelope, ErrorEnvelope> {
    return requestDecodable(.changePaymentMethod(project: project))
  }

  public func clearUserUnseenActivity(input: EmptyInput)
    -> SignalProducer<ClearUserUnseenActivityEnvelope, GraphError> {
    return applyMutation(mutation: ClearUserUnseenActivityMutation(input: input))
  }

  public func deletePaymentMethod(input: PaymentSourceDeleteInput)
    -> SignalProducer<DeletePaymentMethodEnvelope, GraphError> {
    return applyMutation(mutation: PaymentSourceDeleteMutation(input: input))
  }

  public func changeCurrency(input: ChangeCurrencyInput) ->
    SignalProducer<GraphMutationEmptyResponseEnvelope, GraphError> {
    return applyMutation(mutation: UpdateUserProfileMutation(input: input))
  }

  public func delete(image: UpdateDraft.Image, fromDraft draft: UpdateDraft)
    -> SignalProducer<UpdateDraft.Image, ErrorEnvelope> {
    return requestDecodable(.deleteImage(image, fromDraft: draft))
  }

  public func delete(video: UpdateDraft.Video, fromDraft draft: UpdateDraft)
    -> SignalProducer<UpdateDraft.Video, ErrorEnvelope> {
    return requestDecodable(.deleteVideo(video, fromDraft: draft))
  }

  public func exportData() -> SignalProducer<VoidEnvelope, ErrorEnvelope> {
    return requestDecodable(.exportData)
  }

  public func exportDataState()
    -> SignalProducer<ExportDataEnvelope, ErrorEnvelope> {
    return requestDecodable(.exportDataState)
  }

  public func previewUrl(forDraft draft: UpdateDraft) -> URL? {
    return self.serverConfig.apiBaseUrl
      .appendingPathComponent("/v1/projects/\(draft.update.projectId)/updates/draft/preview")
  }

  public func fetchActivities(count: Int?) -> SignalProducer<ActivityEnvelope, ErrorEnvelope> {
    let categories: [Activity.Category] = [
      .backing,
      .cancellation,
      .failure,
      .follow,
      .launch,
      .success,
      .update
    ]
    return requestDecodable(.activities(categories: categories, count: count))
  }

  public func fetchActivities(paginationUrl: String)
    -> SignalProducer<ActivityEnvelope, ErrorEnvelope> {
    return requestPaginationDecodable(paginationUrl)
  }

  public func fetchBacking(forProject project: Project, forUser user: User)
    -> SignalProducer<Backing, ErrorEnvelope> {
    return requestDecodable(.backing(projectId: project.id, backerId: user.id))
  }

  public func fetchComments(paginationUrl url: String) -> SignalProducer<CommentsEnvelope, ErrorEnvelope> {
    return requestPaginationDecodable(url)
  }

  public func fetchComments(project: Project) -> SignalProducer<CommentsEnvelope, ErrorEnvelope> {
    return requestDecodable(.projectComments(project))
  }

  public func fetchComments(update: Update) -> SignalProducer<CommentsEnvelope, ErrorEnvelope> {
    return requestDecodable(.updateComments(update))
  }

  public func fetchConfig() -> SignalProducer<Config, ErrorEnvelope> {
    return requestDecodable(.config)
  }

  public func fetchDiscovery(paginationUrl: String)
    -> SignalProducer<DiscoveryEnvelope, ErrorEnvelope> {
    return requestPaginationDecodable(paginationUrl)
  }

  public func fetchDiscovery(params: DiscoveryParams)
    -> SignalProducer<DiscoveryEnvelope, ErrorEnvelope> {
    return requestDecodable(.discover(params))
  }

  public func fetchFriends() -> SignalProducer<FindFriendsEnvelope, ErrorEnvelope> {
    return requestDecodable(.friends)
  }

  public func fetchFriends(paginationUrl: String)
    -> SignalProducer<FindFriendsEnvelope, ErrorEnvelope> {
    return requestPaginationDecodable(paginationUrl)
  }

  public func fetchFriendStats() -> SignalProducer<FriendStatsEnvelope, ErrorEnvelope> {
    return requestDecodable(.friendStats)
  }

  public func fetchGraphCategories(query: NonEmptySet<Query>)
    -> SignalProducer<RootCategoriesEnvelope, GraphError> {
    return fetch(query: query)
  }

  public func fetchGraphCategory(query: NonEmptySet<Query>)
    -> SignalProducer<CategoryEnvelope, GraphError> {
    return fetch(query: query)
  }

  public func fetchGraphCreditCards(query: NonEmptySet<Query>)
    -> SignalProducer<UserEnvelope<GraphUserCreditCard>, GraphError> {
    return fetch(query: query)
  }

  public func fetchGraphUserAccountFields(query: NonEmptySet<Query>)
    -> SignalProducer<UserEnvelope<GraphUser>, GraphError> {
    return fetch(query: query)
  }

  public func fetchGraphUserBackings(query: NonEmptySet<Query>)
    -> SignalProducer<BackingsEnvelope, ErrorEnvelope> {
    return fetch(query: query)
      .mapError(ErrorEnvelope.envelope(from:))
      .flatMap(BackingsEnvelope.envelopeProducer(from:))
  }

  public func fetchGraphUserEmailFields(query: NonEmptySet<Query>)
    -> SignalProducer<UserEnvelope<UserEmailFields>, GraphError> {
    return fetch(query: query)
  }

  public func fetchManagePledgeViewBacking(query: NonEmptySet<Query>)
    -> SignalProducer<ProjectAndBackingEnvelope, ErrorEnvelope> {
    return fetch(query: query)
      .mapError(ErrorEnvelope.envelope(from:))
      .flatMap(ProjectAndBackingEnvelope.envelopeProducer(from:))
  }

  public func fetchMessageThread(messageThreadId: Int)
    -> SignalProducer<MessageThreadEnvelope, ErrorEnvelope> {
    return requestDecodable(.messagesForThread(messageThreadId: messageThreadId))
  }

  public func fetchMessageThread(backing: Backing)
    -> SignalProducer<MessageThreadEnvelope?, ErrorEnvelope> {
    return requestDecodable(.messagesForBacking(backing))
  }

  public func fetchMessageThreads(mailbox: Mailbox, project: Project?)
    -> SignalProducer<MessageThreadsEnvelope, ErrorEnvelope> {
    return requestDecodable(.messageThreads(mailbox: mailbox, project: project))
  }

  public func fetchMessageThreads(paginationUrl: String)
    -> SignalProducer<MessageThreadsEnvelope, ErrorEnvelope> {
    return requestPaginationDecodable(paginationUrl)
  }

  public func fetchProject(param: Param) -> SignalProducer<Project, ErrorEnvelope> {
    return requestDecodable(.project(param))
  }

  public func fetchProject(_ params: DiscoveryParams) -> SignalProducer<DiscoveryEnvelope, ErrorEnvelope> {
    return requestDecodable(.discover(params |> DiscoveryParams.lens.perPage .~ 1))
  }

  public func fetchProject(project: Project) -> SignalProducer<Project, ErrorEnvelope> {
    return requestDecodable(.project(.id(project.id)))
  }

  public func fetchProjectActivities(forProject project: Project) ->
    SignalProducer<ProjectActivityEnvelope, ErrorEnvelope> {
    return requestDecodable(.projectActivities(project))
  }

  public func fetchProjectActivities(paginationUrl: String)
    -> SignalProducer<ProjectActivityEnvelope, ErrorEnvelope> {
    return requestPaginationDecodable(paginationUrl)
  }

  public func fetchProjectNotifications() -> SignalProducer<[ProjectNotification], ErrorEnvelope> {
    return requestDecodable(.projectNotifications)
  }

  public func fetchProjects(member: Bool) -> SignalProducer<ProjectsEnvelope, ErrorEnvelope> {
    return requestDecodable(.projects(member: member))
  }

  public func fetchProjects(paginationUrl url: String) -> SignalProducer<ProjectsEnvelope, ErrorEnvelope> {
    return requestPaginationDecodable(url)
  }

  public func fetchProjectStats(projectId: Int) ->
    SignalProducer<ProjectStatsEnvelope, ErrorEnvelope> {
    return requestDecodable(.projectStats(projectId: projectId))
  }

  public func fetchRewardAddOnsSelectionViewRewards(query: NonEmptySet<Query>)
    -> SignalProducer<Project, ErrorEnvelope> {
    return fetch(query: query)
      .mapError(ErrorEnvelope.envelope(from:))
      .flatMap(Project.projectProducer(from:))
  }

  public func fetchRewardShippingRules(projectId: Int, rewardId: Int)
    -> SignalProducer<ShippingRulesEnvelope, ErrorEnvelope> {
    return requestDecodable(.shippingRules(projectId: projectId, rewardId: rewardId))
  }

  public func fetchSurveyResponse(surveyResponseId id: Int) -> SignalProducer<SurveyResponse, ErrorEnvelope> {
    return requestDecodable(.surveyResponse(surveyResponseId: id))
  }

  public func fetchUserProjectsBacked() -> SignalProducer<ProjectsEnvelope, ErrorEnvelope> {
    return requestDecodable(.userProjectsBacked)
  }

  public func fetchUserProjectsBacked(paginationUrl url: String)
    -> SignalProducer<ProjectsEnvelope, ErrorEnvelope> {
    return requestPaginationDecodable(url)
  }

  public func fetchUserSelf() -> SignalProducer<User, ErrorEnvelope> {
    return requestDecodable(.userSelf)
  }

  public func fetchUser(userId: Int) -> SignalProducer<User, ErrorEnvelope> {
    return requestDecodable(.user(userId: userId))
  }

  public func fetchUser(_ user: User) -> SignalProducer<User, ErrorEnvelope> {
    return self.fetchUser(userId: user.id)
  }

  public func fetchUpdate(updateId: Int, projectParam: Param)
    -> SignalProducer<Update, ErrorEnvelope> {
    return requestDecodable(.update(updateId: updateId, projectParam: projectParam))
  }

  public func fetchUpdateDraft(forProject project: Project) -> SignalProducer<UpdateDraft, ErrorEnvelope> {
    return requestDecodable(.fetchUpdateDraft(forProject: project))
  }

  public func fetchUnansweredSurveyResponses() -> SignalProducer<[SurveyResponse], ErrorEnvelope> {
    return requestDecodable(.unansweredSurveyResponses)
  }

  public func backingUpdate(forProject project: Project, forUser user: User, received: Bool) ->
    SignalProducer<Backing, ErrorEnvelope> {
    return requestDecodable(.backingUpdate(projectId: project.id, backerId: user.id, received: received))
  }

  public func followAllFriends() -> SignalProducer<VoidEnvelope, ErrorEnvelope> {
    return requestDecodable(.followAllFriends)
  }

  public func followFriend(userId id: Int) -> SignalProducer<User, ErrorEnvelope> {
    return requestDecodable(.followFriend(userId: id))
  }

  public func incrementVideoCompletion(forProject project: Project) ->
    SignalProducer<VoidEnvelope, ErrorEnvelope> {
    let producer = requestDecodable(.incrementVideoCompletion(project: project))
      as SignalProducer<VoidEnvelope, ErrorEnvelope>

    return producer
      .flatMapError { env -> SignalProducer<VoidEnvelope, ErrorEnvelope> in
        if env.ksrCode == .ErrorEnvelopeJSONParsingFailed {
          return .init(value: VoidEnvelope())
        }
        return .init(error: env)
      }
  }

  public func incrementVideoStart(forProject project: Project) ->
    SignalProducer<VoidEnvelope, ErrorEnvelope> {
    let producer = requestDecodable(.incrementVideoStart(project: project))
      as SignalProducer<VoidEnvelope, ErrorEnvelope>

    return producer
      .flatMapError { env -> SignalProducer<VoidEnvelope, ErrorEnvelope> in
        if env.ksrCode == .ErrorEnvelopeJSONParsingFailed {
          return .init(value: VoidEnvelope())
        }
        return .init(error: env)
      }
  }

  public func login(email: String, password: String, code: String?) ->
    SignalProducer<AccessTokenEnvelope, ErrorEnvelope> {
    return requestDecodable(.login(email: email, password: password, code: code))
  }

  public func login(facebookAccessToken: String, code: String?) ->
    SignalProducer<AccessTokenEnvelope, ErrorEnvelope> {
    return requestDecodable(.facebookLogin(facebookAccessToken: facebookAccessToken, code: code))
  }

  public func markAsRead(messageThread: MessageThread) -> SignalProducer<MessageThread, ErrorEnvelope> {
    return requestDecodable(.markAsRead(messageThread))
  }

  public func postComment(_ body: String, toProject project: Project) ->
    SignalProducer<Comment, ErrorEnvelope> {
    return requestDecodable(.postProjectComment(project, body: body))
  }

  public func postComment(_ body: String, toUpdate update: Update) -> SignalProducer<Comment, ErrorEnvelope> {
    return requestDecodable(.postUpdateComment(update, body: body))
  }

  public func publish(draft: UpdateDraft) -> SignalProducer<Update, ErrorEnvelope> {
    return requestDecodable(.publishUpdateDraft(draft))
  }

  public func register(pushToken: String) -> SignalProducer<VoidEnvelope, ErrorEnvelope> {
    return requestDecodable(.registerPushToken(pushToken))
  }

  public func resetPassword(email: String) -> SignalProducer<User, ErrorEnvelope> {
    return requestDecodable(.resetPassword(email: email))
  }

  public func searchMessages(query: String, project: Project?)
    -> SignalProducer<MessageThreadsEnvelope, ErrorEnvelope> {
    return requestDecodable(.searchMessages(query: query, project: project))
  }

  public func sendMessage(body: String, toSubject subject: MessageSubject)
    -> SignalProducer<Message, ErrorEnvelope> {
    return requestDecodable(.sendMessage(body: body, messageSubject: subject))
  }

  public func sendVerificationEmail(input: EmptyInput) ->
    SignalProducer<GraphMutationEmptyResponseEnvelope, GraphError> {
    return applyMutation(mutation: UserSendEmailVerificationMutation(input: input))
  }

  public func signInWithApple(input: SignInWithAppleInput)
    -> SignalProducer<SignInWithAppleEnvelope, GraphError> {
    return applyMutation(mutation: SignInWithAppleMutation(input: input))
  }

  public func signup(
    name: String,
    email: String,
    password: String,
    passwordConfirmation: String,
    sendNewsletters: Bool
  ) -> SignalProducer<AccessTokenEnvelope, ErrorEnvelope> {
    return requestDecodable(.signup(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      sendNewsletters: sendNewsletters
    ))
  }

  public func signup(facebookAccessToken token: String, sendNewsletters: Bool) ->
    SignalProducer<AccessTokenEnvelope, ErrorEnvelope> {
    return requestDecodable(.facebookSignup(facebookAccessToken: token, sendNewsletters: sendNewsletters))
  }

  public func unfollowFriend(userId id: Int) -> SignalProducer<VoidEnvelope, ErrorEnvelope> {
    return requestDecodable(.unfollowFriend(userId: id))
  }

  public func updateBacking(input: UpdateBackingInput) -> SignalProducer<UpdateBackingEnvelope, GraphError> {
    return applyMutation(mutation: UpdateBackingMutation(input: input))
  }

  public func update(draft: UpdateDraft, title: String, body: String, isPublic: Bool)
    -> SignalProducer<UpdateDraft, ErrorEnvelope> {
    return requestDecodable(.updateUpdateDraft(draft, title: title, body: body, isPublic: isPublic))
  }

  public func updatePledge(
    project: Project,
    amount: Double,
    reward: Reward?,
    shippingLocation: Location?,
    tappedReward: Bool
  ) -> SignalProducer<UpdatePledgeEnvelope, ErrorEnvelope> {
    return requestDecodable(
      .updatePledge(
        project: project,
        amount: amount,
        reward: reward,
        shippingLocation: shippingLocation,
        tappedReward: tappedReward
      )
    )
  }

  public func updateProjectNotification(_ notification: ProjectNotification)
    -> SignalProducer<ProjectNotification, ErrorEnvelope> {
    return requestDecodable(.updateProjectNotification(notification: notification))
  }

  public func updateUserSelf(_ user: User) -> SignalProducer<User, ErrorEnvelope> {
    return requestDecodable(.updateUserSelf(user))
  }

  public func unwatchProject(input: WatchProjectInput) ->
    SignalProducer<GraphMutationWatchProjectResponseEnvelope, GraphError> {
    return applyMutation(mutation: UnwatchProjectMutation(input: input))
  }

  public func watchProject(input: WatchProjectInput) ->
    SignalProducer<GraphMutationWatchProjectResponseEnvelope, GraphError> {
    return applyMutation(mutation: WatchProjectMutation(input: input))
  }
}
