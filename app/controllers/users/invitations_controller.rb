class Users::InvitationsController < Devise::InvitationsController
  include AccessControllable

  # Devise::InvitationsController from devise-invitable uses some before_actions to validate
  # data being passed in. We skip those and use our before_action methods to customize
  # access control and error messages.
  skip_before_action :authenticate_inviter!
  skip_before_action :has_invitations_left?
  skip_before_action :resource_from_invitation_token

  before_action :require_sign_in, only: [:new]
  before_action only: [:create] do
    # If an anonymous user tries to send an invitation, send them to the invitation page after sign-in.
    require_sign_in(redirect_after_login: new_user_invitation_path)
  end
  before_action :load_and_authorize_groups, only: [:new, :create]

  authorize_resource :user, only: [:new, :create]
  before_action :require_valid_invitation_token, only: [:edit, :update]

  def create
    redirect_to invitations_path and return if already_invited_other_role?

    if params[:user][:role] == OrganizationLeadRole::TYPE
      organization = @vita_partners.find(params.require(:organization_id))

      super do |invited_user|
        role = OrganizationLeadRole.create(organization: organization)
        invited_user.update(role: role)
      end
    elsif params[:user][:role] == CoalitionLeadRole::TYPE
      coalition = @coalitions.find(params.require(:coalition_id))

      super do |invited_user|
        role = CoalitionLeadRole.create(coalition: coalition)
        invited_user.update(role: role)
      end
    elsif params[:user][:role] == AdminRole::TYPE
      super do |invited_user|
        role = AdminRole.create

        invited_user.update(role: role)
      end
    elsif params[:user][:role] == SiteCoordinatorRole::TYPE
      site = @vita_partners.find(params.require(:site_id))

      super do |invited_user|
        role = SiteCoordinatorRole.create(site: site)
        invited_user.update(role: role)
      end
    elsif params[:user][:role] == ClientSuccessRole::TYPE
      super do |invited_user|
        role = ClientSuccessRole.create

        invited_user.update(role: role)
      end
    elsif params[:user][:role] == GreeterRole::TYPE
      super do |invited_user|
        greeter_params = params.require(:greeter_organization_join_record).permit(organization_ids: []).merge(
          params.require(:greeter_coalition_join_record).permit(coalition_ids: [])
        )

        role = GreeterRole.create(
          coalitions: @coalitions.where(id: greeter_params[:coalition_ids]),
          organizations: @vita_partners.organizations.where(id: greeter_params[:organization_ids]),
        )

        invited_user.update(role: role)
      end
    end
  end

  private

  def already_invited_other_role?
    User.where(email: invite_params[:email]).where.not(role_type: params[:user][:role]).exists?
  end

  def load_and_authorize_groups
    @vita_partners = VitaPartner.accessible_by(current_ability)
    authorize!(:manage, @vita_partners)

    @coalitions = Coalition.accessible_by(current_ability)
    authorize!(:manage, @coalitions)
  end

  # Override superclass method for default params for newly created invites, allowing us to add attributes
  def invite_params
    params.require(:user).permit(:name, :email)
  end

  # Override superclass method for accepted invite params, allowing us to add attributes
  def update_resource_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :invitation_token, :timezone)
  end

  # Path after successfully sending an invite
  def after_invite_path_for(_user)
    invitations_path
  end

  # Path after accepting an invite and setting a password
  def after_accept_path_for(_user)
    hub_user_profile_path
  end

  # replaces #resource_from_invitation_token so we can render a not_found template if the token is bad
  def require_valid_invitation_token
    unless raw_invitation_token.present? && get_user_by_invitation_token
      render :not_found, status: :not_found
    end
  end

  def raw_invitation_token
    # on GET invitation_token is a top-level query param
    return params[:invitation_token] if action_name == "edit"

    update_resource_params[:invitation_token]
  end

  def get_user_by_invitation_token
    self.resource = resource_class.find_by_invitation_token(raw_invitation_token, true)
  end
end
