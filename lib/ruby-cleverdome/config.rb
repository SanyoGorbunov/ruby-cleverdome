module CleverDomeConfiguration
  class CDConfig
    def auth_service_path
      'sandbox.cleverdome.com/CDSSOService/ApiKeyService.svc'
    end

    def widgets_service_path
      'sandbox.cleverdome.com/CDWidgets/Services/Widgets.svc'
    end

    def user_management_service_path
      'sandbox.cleverdome.com/CDWidgets/Services/VendorUserManagement.svc'
    end

    def clever_dome_cert_file
      '../../cert/CleverDomePublic.pem'
    end

    def application_id
      16
    end

    def api_key
      'VWUL]$UY[JY^KgjO104!ecDO#7X+6/y6cUPkZOngIghv3d(Mq(S}=IBc!1rIC#0)_pCnT0V3=s0XMRmcG[wj$5vG&)if[_|ui.Q6nvYvg?Sa1RHX;_8RDv]s0Y$16+|v'
    end

    def test_user_id
      'Test.Jaccomo'
    end

    def archiving_days
      7
    end

    def archive_document
      false
    end
  end
end