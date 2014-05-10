module Uniware
  class Client
    extend Savon::Model

    BASE_URL "https://%s/services/soap/?version=1.5"
    namespace "http://uniware.unicommerce.com/services/"

    def initialize(hostname, username, password)
      @endpoint = BASE_URL % [hostname]
      @facility_base_endpoint = @endpoint + "&facility=%s"
      self.class.endpoint @endpoint
      self.class.wsse_auth username, password
    end

    def facility_endpoint(facility_code)
      @facility_base_endpoint % [facility_code]
    end

    def create_sale_order(data)
      body = {
        "SaleOrder" => {

        }
      }
      perform_operation("CreateSaleOrderRequest", body)
    end

    def get_item_detail(body)
      perform_operation("GetItemDetailRequest", body, facility_endpoint("01"))
    end

    def create_reverse_pickup(body)
      perform_operation("CreateReversePickupRequest", body)
    end

    def update_sale_order_item(body, code)
      perform_operation("UpdateTrackingStatusRequest", body, facility_endpoint("0#{code}"))
    end

    private
      def perform_operation(name, body, endpoint=nil)
        client.wsdl.endpoint = endpoint || @endpoint
        response = client.request :ser, name do
          soap.body = body
        end
      end
  end
end
