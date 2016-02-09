class Admin::BillingSubscriptionsController < AdminController
private
  def eager_load_account(partial=false)
    eager_loads = [:billing_subscription]
    eager_loads << :quota unless partial

    @account      = Account.includes(*eager_loads).find(params[:account_id])
    @subscription = @account.billing_subscription
    @quota        = @account.quota
  end

  def account
    @account
  end

  def subscription
    @subscription ||= @account.try(:billing_subscription)
  end

  def quota
    @quota ||= @account.try(:quota)
  end

  def subscription_params
    params[:billing_subscription]
  end

  def price_per_quantity
    subscription_params[:price_per_quantity]
  end

  def update_contract
    return unless price_per_quantity.present?

    # reload subscription id & obj
    # contract persists on new subscription after upgrade or reset
    eager_load_account(true) if plan.present?
    subscription.update_contract price_per_quantity: price_per_quantity
  end

  def plan
    return 'trial' if subscription_params[:reset].present?

    subscription_params[:plan]
  end

  def upgrade_to_enterprise
    return unless plan == 'enterprise'

    customer_id     = account.billing_provider_customer_id
    payment_gateway = Billing::PaymentGateway.new(customer_id)

    payment_gateway.cancel_subscription

    ActiveRecord::Base.transaction do
      subscription.plan_changed!(plan)
      quota.plan_cancelled!
      quota.plan_changed!(plan)
    end
  end

  def reset_to_trial
    return unless plan == 'trial'

    ActiveRecord::Base.transaction do
      subscription.destroy
      quota.destroy
      account.setup_trial!
    end
  end

  def changing_plans?
    plan.present?
  end

public
  def show
    eager_load_account
  end

  def update
    msg = ["Subscription updated."]

    eager_load_account(true)

    upgrade_to_enterprise
    reset_to_trial

    update_contract
    unless subscription.save
      msg = subscription.errors.full_messages
    end

    flash[:notice] = msg
    redirect_to :back
  end
end