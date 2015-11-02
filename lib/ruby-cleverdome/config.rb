module CleverDomeConfiguration
  class CDConfig
    def authServicePath
      'sandbox.cleverdome.com/CDSSOService/ApiKeyService.svc'
    end

    def widgetsServicePath
      'sandbox.cleverdome.com/CDWidgets/Services/Widgets.svc'
    end

    def userManagementServicePath
      'sandbox.cleverdome.com/CDWidgets/Services/VendorUserManagement.svc'
    end

    def cleverDomeCertFile
      File.expand_path('../../../cert/CleverDomePublic.pem', __FILE__)
    end

    def applicationID
      16
    end

    def apiKey
      'VWUL]$UY[JY^KgjO104!ecDO#7X+6/y6cUPkZOngIghv3d(Mq(S}=IBc!1rIC#0)_pCnT0V3=s0XMRmcG[wj$5vG&)if[_|ui.Q6nvYvg?Sa1RHX;_8RDv]s0Y$16+|v'
    end

    def testUserID
      'Test.Jaccomo'
    end

    def archiving_days
      7
    end

    def archive_document
      false
    end

    #our services are ip-protected. Please specify IP-addressed from which users are permitted to use the session
    def test_ip_addresses
      ['127.0.0.1', '127.0.0.2', '192.168.0.*']
    end
  end
end