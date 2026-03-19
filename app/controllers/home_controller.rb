class HomeController < ApplicationController
  def index
    @stats = {
      legal_entities: LegalEntity.count,
      operators: Operator.count,
      payment_orders: PaymentOrder.count,
      sardine_alerts: SardineAlert.count,
      cases: InvestigationCase.count,
      case_events: CaseEvent.count,
      rfis: Rfi.count,
      persona_inquiries: PersonaInquiry.count,
      open_cases: InvestigationCase.where(status: "open").count
    }
  end
end
