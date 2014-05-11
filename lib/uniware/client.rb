require 'savon'

module Uniware
  class Client
    extend Savon::Model

    namespace "http://uniware.unicommerce.com/services/"
    BASE_URL = "https://%s/services/soap/?version=1.5"
    SALE_ORDER_XML = <<-SXML
      <ser:SaleOrder>
        %s
        <ser:Addresses>%s</ser:Addresses>
        %s
        <ser:SaleOrderItems>%s</ser:SaleOrderItems>
        <ser:CustomFields>%s</ser:CustomFields>
      </ser:SaleOrder>
    SXML

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
      addresses = data.delete("Addresses")
      items = data.delete("SaleOrderItems")
      custom_fields = data.delete("CustomFields")
      tmp_addresses = []
      tmp_address_refs = []
      addresses.keys.each_with_index do |atype,i|
        tmp_addresses << Gyoku.xml({
          ns_key("Address") => namespaced_hash(addresses[atype]),
          :attributes! => {ns_key("Address") => {"id" => i+1}}
        })
        atype_key = ns_key(atype + "Address")
        tmp_address_refs << Gyoku.xml({
          atype_key => {},
          :attributes! => {atype_key => {"ref" => i+1}}
        })
      end
      order_items = items.map do |item|
        namespaced_hash(item)
      end
      cfields = custom_fields.map do |f|
        Gyoku.xml({
          ns_key("CustomField") => {},
          :attributes! => {
            ns_key("CustomField") => {
              "name" => f["name"],
              "value" => f["value"]
            }
          }
        })
      end
      body = SALE_ORDER_XML.gsub(/\s+/, '') % [Gyoku.xml(namespaced_hash(data)),
                                               tmp_addresses.join,
                                               tmp_address_refs.join,
                                               Gyoku.xml({ns_key("SaleOrderItem") => order_items}),
                                               cfields.join]
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

      def ns_key(s)
        'ser:' + s
      end

      def namespaced_hash(h)
        t = {}
        h.each do |k,v|
          t[ns_key(k)] = v
        end
        return t
      end
  end
end
