import KsApi
import Library
import Prelude
import Prelude_UIKit
import UIKit

internal protocol CommentsEmptyStateCellDelegate: AnyObject {
  /// Call when we should navigate back to the project.
  func commentEmptyStateCellGoBackToProject()

  /// Call when we should navigate to the comment dialog.
  func commentEmptyStateCellGoToCommentDialog()

  /// Call when we should navigate to the login tout.
  func commentEmptyStateCellGoToLoginTout()
}

internal final class CommentsEmptyStateCell: UITableViewCell, ValueCell {
  internal weak var delegate: CommentsEmptyStateCellDelegate?
  fileprivate let viewModel: CommentsEmptyStateCellViewModelType = CommentsEmptyStateCellViewModel()

  @IBOutlet fileprivate var backProjectButton: UIButton!
  @IBOutlet fileprivate var leaveACommentButton: UIButton!
  @IBOutlet fileprivate var loginButton: UIButton!
  @IBOutlet fileprivate var rootStackView: UIStackView!
  @IBOutlet fileprivate var subtitleLabel: UILabel!
  @IBOutlet fileprivate var titleLabel: UILabel!

  internal override func awakeFromNib() {
    super.awakeFromNib()

    self.backProjectButton.addTarget(
      self,
      action: #selector(self.backProjectTapped),
      for: .touchUpInside
    )

    self.leaveACommentButton.addTarget(
      self,
      action: #selector(self.leaveACommentTapped),
      for: .touchUpInside
    )

    self.loginButton.addTarget(self, action: #selector(self.loginTapped), for: .touchUpInside)
  }

  internal override func bindStyles() {
    super.bindStyles()

    _ = self
      |> baseTableViewCellStyle()
      |> CommentsEmptyStateCell.lens.backgroundColor .~ .white
      |> CommentsEmptyStateCell.lens.contentView.layoutMargins .~
      .init(topBottom: Styles.grid(9), leftRight: Styles.grid(3))

    _ = self.leaveACommentButton
      |> greyButtonStyle
      |> UIButton.lens.title(for: .normal) %~ { _ in
        Strings.project_comments_empty_state_backer_button()
      }
      |> UIButton.lens.accessibilityLabel %~ { _ in Strings.general_navigation_buttons_comment() }
      |> UIButton.lens.accessibilityHint %~ { _ in
        Strings.accessibility_dashboard_buttons_post_update_hint()
      }

    _ = self.backProjectButton
      |> greyButtonStyle
      |> UIButton.lens.title(for: .normal) %~ { _ in Strings.project_back_button() }

    _ = self.loginButton
      |> greyButtonStyle
      |> UIButton.lens.title(for: .normal) %~ { _ in Strings.login_buttons_log_in() }

    _ = self.rootStackView
      |> UIStackView.lens.alignment .~ .center
      |> UIStackView.lens.spacing .~ Styles.grid(5)

    _ = self.subtitleLabel
      |> UILabel.lens.font .~ .ksr_body(size: 16.0)
      |> UILabel.lens.textColor .~ .ksr_text_dark_grey_400
      |> UILabel.lens.textAlignment .~ .center

    _ = self.titleLabel
      |> UILabel.lens.font .~ .ksr_headline(size: 18.0)
      |> UILabel.lens.textColor .~ .ksr_soft_black
      |> UILabel.lens.text %~ { _ in Strings.No_comments_yet() }
  }

  internal override func bindViewModel() {
    super.bindViewModel()

    self.backProjectButton.rac.hidden = self.viewModel.outputs.backProjectButtonHidden
    self.subtitleLabel.rac.text = self.viewModel.outputs.subtitleText
    self.subtitleLabel.rac.hidden = self.viewModel.outputs.subtitleIsHidden
    self.loginButton.rac.hidden = self.viewModel.outputs.loginButtonHidden
    self.leaveACommentButton.rac.hidden = self.viewModel.outputs.leaveACommentButtonHidden

    self.viewModel.outputs.goToCommentDialog
      .observeForUI()
      .observeValues { [weak self] in self?.delegate?.commentEmptyStateCellGoToCommentDialog() }

    self.viewModel.outputs.goToLoginTout
      .observeForUI()
      .observeValues { [weak self] in self?.delegate?.commentEmptyStateCellGoToLoginTout() }

    self.viewModel.outputs.goBackToProject
      .observeForUI()
      .observeValues { [weak self] in self?.delegate?.commentEmptyStateCellGoBackToProject() }
  }

  internal func configureWith(value: (Project, Update?)) {
    self.viewModel.inputs.configureWith(project: value.0, update: value.1)
  }

  @objc fileprivate func backProjectTapped() {
    self.viewModel.inputs.backProjectTapped()
  }

  @objc fileprivate func loginTapped() {
    self.viewModel.inputs.loginTapped()
  }

  @objc fileprivate func leaveACommentTapped() {
    self.viewModel.inputs.leaveACommentTapped()
  }
}
