require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe Uniware do
  it "must be defined" do
    Uniware::Version.should_not be_nil
  end

  describe Uniware::Client do
    let(:host) { 'staging.unicommerce.com' }
    let(:username) { 'uniware_user' }
    let(:password) { 'random_password' }

    it "should create sale order" do
      client = Uniware::Client.new(host, username, password)
      client.create_sale_order({
        "Code" => "Order001",
        "DisplayOrderCode" => "Order001",
        "DisplayOrderDateTime" => "2014-05-11T10:36:00Z",
        "NotificationEmail" => "johndoe@gmail.com",
        "NotificationMobile" => "+911234567890",
        "CashOnDelivery" => true,
        "Addresses" => {
          "Shipping" => {
            "Name" => "John Doe",
            "AddressLine1" => "Shipping Address 001",
            "City" => "Bangalore",
            "State" => "Karnataka",
            "Country" => "IN",
            "Pincode" => "560001",
            "Phone" => "+911234567890"
          },
          "Billing" => {
            "Name" => "John Doe",
            "AddressLine1" => "Billing Address 001",
            "City" => "Bangalore",
            "State" => "Karnataka",
            "Country" => "IN",
            "Pincode" => "560001",
            "Phone" => "+911234567890"
          }
        },
        "SaleOrderItems" => [
          {"ItemSKU" => "SKU_001",
           "ShippingMethodCode" => "STD",
           "TotalPrice" => 10308,
           "SellingPrice" => 10308,
           "Discount" => 2691,
           "Code" => 5501,
           "CustomFields" => [
             {"name" => "itemCustomField001", "value" => "itemCustomField001_Value"},
             {"name" => "itemCustomField002", "value" => "itemCustomField002_Value"}
           ]},
          {"ItemSKU" => "SKU_002",
           "ShippingMethodCode" => "STD",
           "TotalPrice" => 5154,
           "SellingPrice" => 5154,
           "Discount" => 1345,
           "Code" => "5502-1"},
          {"ItemSKU" => "SKU_002",
           "ShippingMethodCode" => "STD",
           "TotalPrice" => 5154,
           "SellingPrice" => 5154,
           "Discount" => 1345,
           "Code" => "5502-2"},
          {"ItemSKU" => "SKU_003",
           "ShippingMethodCode" => "STD",
           "TotalPrice" => 9082,
           "SellingPrice" => 9082,
           "Discount" => 917,
           "VoucherCode" => "special_offer",
           "Code" => 5503}
        ],
        "CustomFields" => [
          {"name" => "customField001", "value" => "customField001_Value"},
          {"name" => "customField002", "value" => "customField002_Value"}
        ]
      })
    end
  end
end
