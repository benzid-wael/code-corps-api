defmodule CodeCorps.StripeConnectAccountViewTest do
  use CodeCorps.ConnCase, async: true

  import Phoenix.View, only: [render: 3]

  test "renders all attributes and relationships properly" do
    organization = insert(:organization)
    account = insert(:stripe_connect_account,
      organization: organization,
      verification_disabled_reason: "fields_needed",
      verification_fields_needed: ["legal_entity.first_name", "legal_entity.last_name"]
    )

    rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)

    expected_json = %{
      "data" => %{
        "attributes" => %{
          "bank-account-status" => "pending_requirement",
          "business-name" => account.business_name,
          "business-url" => account.business_url,
          "can-accept-donations" => true,
          "charges-enabled" => account.charges_enabled,
          "country" => account.country,
          "default-currency" => account.default_currency,
          "details-submitted" => account.details_submitted,
          "display-name" => account.display_name,
          "email" => account.email,
          "id-from-stripe" => account.id_from_stripe,
          "inserted-at" => account.inserted_at,
          "managed" => account.managed,
          "personal-id-number-status" => "pending_requirement",
          "recipient-status" => "required",
          "support-email" => account.support_email,
          "support-phone" => account.support_phone,
          "support-url" => account.support_url,
          "transfers-enabled" => account.transfers_enabled,
          "updated-at" => account.updated_at,
          "verification-disabled-reason" => account.verification_disabled_reason,
          "verification-document-status" => "pending_requirement",
          "verification-due-by" => account.verification_due_by,
          "verification-fields-needed" => account.verification_fields_needed
        },
        "id" => account.id |> Integer.to_string,
        "relationships" => %{
          "organization" => %{
            "data" => %{"id" => organization.id |> Integer.to_string, "type" => "organization"}
          }
        },
        "type" => "stripe-connect-account",
      },
      "jsonapi" => %{
        "version" => "1.0"
      }
    }

    assert rendered_json == expected_json
  end

  test "renders can-accept-donations as true in prod when charges-enabled is true" do
    Application.put_env(:code_corps, :stripe_env, :prod)

    organization = insert(:organization)
    account = insert(:stripe_connect_account, organization: organization, charges_enabled: true)

    rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
    assert rendered_json["data"]["attributes"]["can-accept-donations"] == true
    assert rendered_json["data"]["attributes"]["charges-enabled"] == true

    Application.put_env(:code_corps, :stripe_env, :test)
  end

  test "renders can-accept-donations as false in prod when charges-enabled is false" do
    Application.put_env(:code_corps, :stripe_env, :prod)

    organization = insert(:organization)
    account = insert(:stripe_connect_account, organization: organization, charges_enabled: false)

    rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
    assert rendered_json["data"]["attributes"]["can-accept-donations"] == false
    assert rendered_json["data"]["attributes"]["charges-enabled"] == false

    Application.put_env(:code_corps, :stripe_env, :test)
  end

  test "renders can-accept-donations as true in test when charges-enabled is false" do
    organization = insert(:organization)
    account = insert(:stripe_connect_account, organization: organization, charges_enabled: false)

    rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
    assert rendered_json["data"]["attributes"]["can-accept-donations"] == true
    assert rendered_json["data"]["attributes"]["charges-enabled"] == false
  end

  describe "recipient-status" do
    test "renders as 'required' by default" do
      account = insert(:stripe_connect_account)
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["recipient-status"] == "required"
    end

    test "renders as 'verifying' when appropriate" do
      account = insert(:stripe_connect_account, legal_entity_verification_status: "pending")
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["recipient-status"] == "verifying"
    end

    test "renders as 'verified' when appropriate" do
      account = insert(:stripe_connect_account, legal_entity_verification_status: "verified")
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["recipient-status"] == "verified"
    end
  end

  describe "verification-document-status" do
    test "renders as 'pending_requirement' by default" do
      account = insert(:stripe_connect_account)
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["verification-document-status"] == "pending_requirement"
    end

    test "renders as 'pending_requirement' when appropriate" do
      account = insert(
        :stripe_connect_account,
        legal_entity_verification_document: nil,
        verification_fields_needed: ["legal_entity.type"])
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["verification-document-status"] == "pending_requirement"
    end

    test "renders as 'required' when appropriate" do
      account = insert(
        :stripe_connect_account,
        legal_entity_verification_document: nil,
        verification_fields_needed: ["legal_entity.verification.document"])
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["verification-document-status"] == "required"
    end

    test "renders as 'verifying' when appropriate" do
      account = insert(
        :stripe_connect_account,
        legal_entity_verification_document: "file_123",
        legal_entity_verification_status: "pending")
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["verification-document-status"] == "verifying"
    end

    test "renders as 'verified' when no fields" do
      account = insert(
        :stripe_connect_account,
        verification_fields_needed: nil)
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["verification-document-status"] == "verified"
    end

    test "renders as 'verified' when appropriate" do
      account = insert(
        :stripe_connect_account,
        legal_entity_verification_document: "file_123",
        verification_fields_needed: ["legal_entity.personal_id_number"])
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["verification-document-status"] == "verified"
    end

    test "renders as 'errored' when appropriate" do
      account = insert(
        :stripe_connect_account,
        legal_entity_verification_document: "file_123",
        verification_fields_needed: ["legal_entity.verification.document"])
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["verification-document-status"] == "errored"
    end
  end

  describe "personal-id-number-status" do
    @account_default %Stripe.Account{}
    test "renders as 'pending_requirement' by default" do
      account = insert(:stripe_connect_account)
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["personal-id-number-status"] == "pending_requirement"
    end

    test "renders as 'pending_requirement' when appropriate" do
      account = insert(
        :stripe_connect_account,
        legal_entity_personal_id_number_provided: false,
        verification_fields_needed: ["legal_entity.type"])
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["personal-id-number-status"] == "pending_requirement"
    end

    test "renders as 'required' when appropriate" do
      account = insert(
        :stripe_connect_account,
        legal_entity_personal_id_number_provided: false,
        verification_fields_needed: ["legal_entity.personal_id_number"])
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["personal-id-number-status"] == "required"
    end

    test "renders as 'verifying' when appropriate" do
      account = insert(
        :stripe_connect_account,
        legal_entity_personal_id_number_provided: true,
        legal_entity_verification_status: "pending")
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["personal-id-number-status"] == "verifying"
    end

    test "renders as 'verified' when no fields" do
      account = insert(
        :stripe_connect_account,
        verification_fields_needed: nil)
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["personal-id-number-status"] == "verified"
    end

    test "renders as 'verified' when appropriate" do
      account = insert(
        :stripe_connect_account,
        legal_entity_personal_id_number_provided: true,
        verification_fields_needed: ["external_account"])
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["personal-id-number-status"] == "verified"
    end
  end

  describe "bank-account-status" do
    test "renders as 'pending_requirement' by default" do
      account = insert(:stripe_connect_account)
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["bank-account-status"] == "pending_requirement"
    end

    test "renders as 'pending_requirement' when appropriate" do
      account = insert(
        :stripe_connect_account,
        legal_entity_verification_status: "pending",
        verification_fields_needed: ["external_account"])
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["bank-account-status"] == "pending_requirement"
    end

    test "renders as 'required' when appropriate" do
      account = insert(
        :stripe_connect_account,
        legal_entity_verification_status: "verified",
        verification_fields_needed: ["external_account"])
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["bank-account-status"] == "required"
    end

    test "renders as 'verified' when appropriate" do
      account = insert(
        :stripe_connect_account,
        legal_entity_verification_status: "verified",
        verification_fields_needed: [])
      rendered_json = render(CodeCorps.StripeConnectAccountView, "show.json-api", data: account)
      assert rendered_json["data"]["attributes"]["bank-account-status"] == "verified"
    end
  end
end
