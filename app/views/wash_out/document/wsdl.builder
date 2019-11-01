xml.instruct!
xml.tag! "wsdl:definitions", 'xmlns:wsdl' => 'http://schemas.xmlsoap.org/wsdl/',
                'xmlns:wsu' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                'xmlns:wsp' => 'http://schemas.xmlsoap.org/ws/2004/09/policy',
                'name' => @name,
                # 'elementFormDefault' => "qualified",
                'targetNamespace' => @namespace,
                'xmlns:tns' => @namespace do

  xml.tag! "wsdl:documentation"
  xml.tag! "wsp:UsingPolicy", "wsdl:required" => "true"
  unless @wsp_policy.nil?
    xml.tag! "wsp:Policy", "wsu:Id" => @wsp_policy
  end

  xml.tag! "wsdl:types" do
    xml.tag! "xsd:schema", :"xmlns:xsd" => 'http://www.w3.org/2001/XMLSchema' do
      defined = []
      @map.each do |operation, formats|
        (formats[:in] + formats[:out]).each do |p|
          wsdl_type xml, p, defined
        end
      end
    end
  end

  @map.each do |operation, formats|
    xml.tag! "wsdl:message", :name => "#{operation}" do
      formats[:in].each do |p|
        xml.tag! "wsdl:part", wsdl_occurence(p, false, :name => p.name, :type => p.namespaced_type)
      end
    end
    xml.tag! "wsdl:message", :name => formats[:response_tag] do
      formats[:out].each do |p|
        xml.tag! "wsdl:part", wsdl_occurence(p, false, :name => p.name, :type => p.namespaced_type)
      end
    end
  end

  xml.tag! "wsdl:portType", :name => "#{@name}_port" do
    @map.each do |operation, formats|
      xml.tag! "wsdl:operation", :name => operation do
        xml.tag! "wsdl:input", :message => "tns:#{operation}"
        xml.tag! "wsdl:output", :message => "tns:#{formats[:response_tag]}"
      end
    end
  end

  xml.tag! "wsdl:binding", :name => "#{@name}_binding", :type => "tns:#{@name}_port" do
    xml.tag! "soap:binding", :"xmlns:soap"=>"http://schemas.xmlsoap.org/wsdl/soap/", :style => 'document', :transport => 'http://schemas.xmlsoap.org/soap/http', :style => "document"
    @map.keys.each do |operation|
      xml.tag! "wsdl:operation", :name => operation do
        xml.tag! "soap:operation", :"xmlns:soap"=>"http://schemas.xmlsoap.org/wsdl/soap/", :soapAction => operation
        xml.tag! "wsdl:input" do
          xml.tag! "soap:body", :"xmlns:soap"=>"http://schemas.xmlsoap.org/wsdl/soap/",
            :use => "literal"
        end
        xml.tag! "wsdl:output" do
          xml.tag! "soap:body", :"xmlns:soap"=>"http://schemas.xmlsoap.org/wsdl/soap/",
            :use => "literal"
        end
      end
    end
  end

  xml.tag! "wsdl:service", :name => @service_name do
    xml.tag! "wsdl:port", :name => "#{@name}_port", :binding => "tns:#{@name}_binding" do
      xml.tag! "soap:address", :"xmlns:soap"=>"http://schemas.xmlsoap.org/wsdl/soap/", :location => WashOut::Router.url(request, @name)
    end
  end
end
