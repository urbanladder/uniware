require 'savon'

module Uniware
  class Client
    extend Savon::Model

    namespace "http://uniware.unicommerce.com/services/"
    BASE_URL = "https://%s/services/soap/?version=1.6"
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
        tmp_addresses << element_with_attributes(ns_key("Address"),
                                                 {"id" => i+1},
                                                 namespaced_hash(addresses[atype]))
        atype_key = ns_key(atype + "Address")
        tmp_address_refs << element_with_attributes(atype_key, {"ref" => i+1})
      end
      order_items = items.map do |item|
        if item.key?("CustomFields")
          item_cfields = item.delete("CustomFields").map do |f|
            element_with_attributes(ns_key("CustomField"),
                                    {"name" => f["name"], "value" => f["value"]})
          end
          item["CustomFields!"] = item_cfields.join
        end
        namespaced_hash(item)
      end
      cfields = custom_fields.map do |f|
        element_with_attributes(ns_key("CustomField"),
                                {"name" => f["name"], "value" => f["value"]})
      end
      body = SALE_ORDER_XML.gsub(/\s+/, '') % [Gyoku.xml(namespaced_hash(data)),
                                               tmp_addresses.join,
                                               tmp_address_refs.join,
                                               Gyoku.xml({ns_key("SaleOrderItem") => order_items}),
                                               cfields.join]
      perform_operation("CreateSaleOrderRequest", body)
    end

    def get_item_detail(barcode, facility_code)
      body = Gyoku.xml(namespaced_hash({"ItemCode" => barcode}))
      perform_operation("GetItemDetailRequest", body, facility_endpoint(facility_code))
    end

    def create_reverse_pickup(data, code)
      tmp_body = {}
      tmp_code = {}
      address = data.delete("Address")
      tmp_address = []
      item_code = data.delete("SaleOrderItemCode")
      action_code = data.delete("ActionCode")
      reason = data.delete("Reason")
      items = {ns_key("ReversePickupItem") => {
                ns_key("SaleOrderItemCode") => item_code,
                ns_key("Reason") => reason}}
      tmp_body = namespaced_hash(data)
      tmp_body[ns_key("ReversePickupItems")] = items
      tmp_address << element_with_attributes(ns_key("Address"),
                                                 {"id" => 1},
                                                 namespaced_hash(address))
      tmp_code[ns_key("ActionCode")] = action_code
      body = Gyoku.xml(tmp_body) + tmp_address[0] + Gyoku.xml(tmp_code)
      perform_operation("CreateReversePickupRequest", body, facility_endpoint("#{code}"))
    end
    
    def create_vendor(data, code)
      body = Gyoku.xml(nested_namespaced_hash(data))
      perform_operation("CreateVendorRequest", body, facility_endpoint("#{code}"))
    end

    def update_vendor(data, code)
      body = Gyoku.xml(nested_namespaced_hash(data))
      perform_operation("EditVendorRequest", body, facility_endpoint("#{code}"))
    end

    def create_or_update_item(data)
      cf = ""
      if data.has_key?("CustomFields")
        custom_data = data.delete("CustomFields")
        cf = custom_fields(custom_data)
      end
      body = Gyoku.xml(namespaced_hash(data))
      body = body + cf
      perform_operation("CreateOrEditItemTypeRequest", body)
    end 
    
    def create_or_update_vendor_item(data, code)
      cf = ""
      if data.has_key?("CustomFields")
        custom_data = data.delete("CustomFields")
        cf = custom_fields(custom_data)
      end
      body = Gyoku.xml(namespaced_hash(data))
      body = body + cf
      perform_operation("CreateOrEditVendorItemTypeRequest", body, facility_endpoint("#{code}"))
    end

    def update_sale_order_item(data, code)
      body = Gyoku.xml(namespaced_hash(data))
      perform_operation("UpdateTrackingStatusRequest", body, facility_endpoint("#{code}"))
    end

    def create_approved_purchase_order(data, code)
      hash_data = {"PurchaseOrderCode" => data["PurchaseOrderCode"],
                   "VendorCode" => data["VendorCode"],
                   "VendorAgreementName" => data["VendorAgreementName"],
                   "CurrencyCode" => data["CurrencyCode"],
                   "DeliveryDate" => data["DeliveryDate"]}
      purchase_order_items = ''
      custom_field_values = ''
      if data["PurchaseOrderItems"].present?
        purchase_order_items = purchase_order_items_format(data["PurchaseOrderItems"])
      end
      if data["CustomFields"].present?
          custom_field_values = custom_fields_po(data["CustomFields"])
      end
      body = Gyoku.xml(namespaced_hash(hash_data))
      body = body + purchase_order_items + custom_field_values
      perform_operation("CreateApprovedPurchaseOrderRequest", body, facility_endpoint("#{code}"))
    end

    def create_pending_purchase_order(data, code)
      hash_data = {"PurchaseOrderCode" => data["PurchaseOrderCode"],
                   "VendorCode" => data["VendorCode"],
                   "VendorAgreementName" => data["VendorAgreementName"],
                   "CurrencyCode" => data["CurrencyCode"],
                   "DeliveryDate" => data["DeliveryDate"]}
      body = Gyoku.xml(namespaced_hash(hash_data))
      perform_operation("CreatePurchaseOrderRequest", body, facility_endpoint("#{code}"))
    end

    private
      def perform_operation(name, body, endpoint=nil)
        client.wsdl.endpoint = endpoint || @endpoint
        response = client.request :ser, name do
          soap.body = body
        end
      end
      
      def custom_fields(data)
        cfields = data.map do |k, v|
          element_with_attributes(ns_key("CustomField"), {"name" => k, "value" => v})
        end
        cfields = cfields.join
        return "<ser:CustomFields>%s</ser:CustomFields>" % [cfields]
      end

      
      def custom_fields_po(data)
        cfields = data.map do |f|
          element_with_attributes(ns_key("CustomField"),
                                {"name" => f["name"], "value" => f["value"]})
        end
        return "<ser:CustomFields>%s</ser:CustomFields>" % cfields.join
      end

      def purchase_order_items_format (data)
        result = ""
        data.each do |f|
          hash_items = {"ItemSKU" => f["ItemSKU"],
                        "Quantity" => f["Quantity"], 
                        "UnitPrice" => f["UnitPrice"]}
          if f["MaxRetailPrice"].present?
            hash_items.merge!("MaxRetailPrice" => f["MaxRetailPrice"])
          end
          if f["Discount"].present?
            hash_items.merge!("Discount" => f["Discount"])
          end
          if f["TaxTypeCode"].present?
            hash_items.merge!("TaxTypeCode" => f["TaxTypeCode"])
          end
          items = Gyoku.xml(namespaced_hash(hash_items))
          result_field = "<ser:PurchaseOrderItem>%s</ser:PurchaseOrderItem>" % items
          result += result_field
        end
        return "<ser:PurchaseOrderItems>%s</ser:PurchaseOrderItems>" % result
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
      
      def nested_namespaced_hash(h)
        t = {}
        h.each do |k,v|
          if v.is_a?(Hash)
            t[ns_key(k)] = nested_namespaced_hash(v)
          elsif v.is_a?(Array)
            t[ns_key(k)] = []
            v.each do |x|
                t[ns_key(k)] << nested_namespaced_hash(x)
            end
          else
            t[ns_key(k)] = v
          end
        end
        return t
      end

      def element_with_attributes(name, attrs, data={})
        Gyoku.xml({
          name => data,
          :attributes! => {name => attrs}
        })
      end
  end
end
