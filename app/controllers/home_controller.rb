class HomeController < ApplicationController
  def index
    @stats = {
      addresses: Address.count,
      programs: Program.count,
      bank_capabilities: BankCapability.count,
      individuals: Individual.count,
      businesses: Business.count,
      legal_entities: LegalEntity.count,
      legal_entity_relationships: LegalEntityRelationship.count,
      bank_legal_entities: BankLegalEntity.count,
      accounts: Account.count,
      account_balances: AccountBalance.count,
      settlement_accounts: SettlementAccount.count,
      program_limits: ProgramLimit.count,
      account_capabilities: AccountCapability.count,
      program_entitlements: ProgramEntitlement.count,
      transfers: Transfer.count,
      transfer_references: TransferReference.count,
      transfer_seasonings: Transfer::Seasoning.count,
      books: Book.count,
      returns: Return.count,
      ach_nocs: AchNoc.count,
      verifications: Verification.count,
      decisions: Decision.count,
      evaluations: Evaluation.count,
      documents: Document.count,
      identifications: Identification.count,
      failed_sidekiq_pushes: FailedSidekiqPush.count,
      turbogrid_search_scopes: Turbogrid::SearchScope.count,
      turbogrid_grid_states: Turbogrid::GridState.count,
    }
  end
end
