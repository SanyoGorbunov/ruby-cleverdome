module CleverDomeConfiguration
  class CDConfig
    def authServicePath
      'dev.cleverdome.com/CDSSOService/ApiKeyService.svc'
    end

    def widgetsServicePath
      'sandbox.cleverdome.com/CDWidgets/Services/Widgets.svc'
    end

    def cleverDomeCertFile
      '../../cert/CleverDomePublic.pem'
    end
  end
end