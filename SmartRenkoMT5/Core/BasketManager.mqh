//+------------------------------------------------------------------+
//| Basket Manager - Concrete Implementation                         |
//+------------------------------------------------------------------+
#ifndef BASKETMANAGER_MQH_GUARD
#define BASKETMANAGER_MQH_GUARD

#include "Types.mqh"
#include "Interfaces.mqh"
#include "PersistenceLayer.mqh"

class CBasketManager : public IBasketManager
{
private:
   string                  m_symbol;
   long                    m_magic_number;
   IPersistenceLayer*      m_persistence;
   SBasket                 m_active_basket;
   bool                    m_has_active_basket;
   int                     m_basket_counter;
   datetime                m_last_basket_time;
   string                  m_status;

    bool                    IsTransitionValid(const ENUM_BASKET_STATE current, const ENUM_BASKET_STATE target);
    string                  GenerateBasketId();

public:
   CBasketManager();
   virtual ~CBasketManager();
   
   virtual bool OnInit(const string symbol, const long magic_number, IPersistenceLayer* persistence);
   virtual void OnDeinit();
   
   virtual bool CreateBasket(const ENUM_POSITION_TYPE direction);
   virtual bool GetActiveBasket(SBasket &basket);
   virtual bool UpdateBasketState(const string basket_id, const ENUM_BASKET_STATE new_state);
   virtual bool CloseBasket(const string basket_id, const ENUM_CLOSURE_REASON reason);
   virtual bool AddEntry(const string basket_id);
   virtual bool ReconstructFromPositions();
   virtual bool ReconstructFromPersistence();
   virtual bool SetStartBalance(const string basket_id, const double balance);
   virtual string GetDiagnostics();
   virtual int GetActiveBasketCount();
};

//+------------------------------------------------------------------+
//| CBasketManager Implementation                                    |
//+------------------------------------------------------------------+
CBasketManager::CBasketManager() : m_symbol(""),
   m_magic_number(0),
   m_persistence(NULL),
   m_has_active_basket(false),
   m_basket_counter(0),
   m_last_basket_time(0),
   m_status("idle")
{
   ZeroMemory(m_active_basket);
}

CBasketManager::~CBasketManager()
{
   OnDeinit();
}

bool CBasketManager::OnInit(const string symbol, const long magic_number, IPersistenceLayer* persistence)
{
   m_symbol = symbol;
   m_magic_number = magic_number;
   m_persistence = persistence;
   m_has_active_basket = false;
   m_basket_counter = 0;
   m_last_basket_time = 0;
   m_status = "initialized";
   ZeroMemory(m_active_basket);
   return true;
}

void CBasketManager::OnDeinit()
{
   m_persistence = NULL;
   m_has_active_basket = false;
   m_status = "deinitialized";
}

string CBasketManager::GenerateBasketId()
{
   string symbol_part = m_symbol;
   StringReplace(symbol_part, " ", "_");
   StringReplace(symbol_part, "/", "_");
   
   datetime now = TimeCurrent();
   if(now == m_last_basket_time)
      m_basket_counter++;
   else
   {
      m_basket_counter = 1;
      m_last_basket_time = now;
   }
   
   return StringConcatenate("BASKET_", symbol_part, "_", IntegerToString(m_magic_number), "_", IntegerToString(now), "_", IntegerToString(m_basket_counter));
}

bool CBasketManager::IsTransitionValid(const ENUM_BASKET_STATE current, const ENUM_BASKET_STATE target)
{
   if(current == target) return true;
   
   switch(current)
   {
      case BASKET_STATE_IDLE:
         return (target == BASKET_STATE_PENDING_FIRST_ENTRY || target == BASKET_STATE_RECOVERY_REBUILD);
         
      case BASKET_STATE_PENDING_FIRST_ENTRY:
         return (target == BASKET_STATE_ACTIVE || target == BASKET_STATE_IDLE || target == BASKET_STATE_RECOVERY_REBUILD);
         
      case BASKET_STATE_ACTIVE:
         return (target == BASKET_STATE_TRAILING_ACTIVE || target == BASKET_STATE_CLOSING || target == BASKET_STATE_RECOVERY_REBUILD);
         
      case BASKET_STATE_TRAILING_ACTIVE:
         return (target == BASKET_STATE_CLOSING || target == BASKET_STATE_ACTIVE || target == BASKET_STATE_RECOVERY_REBUILD);
         
      case BASKET_STATE_CLOSING:
         return (target == BASKET_STATE_CLOSED || target == BASKET_STATE_RECOVERY_REBUILD);
         
      case BASKET_STATE_CLOSED:
         return (target == BASKET_STATE_IDLE || target == BASKET_STATE_RECOVERY_REBUILD);
         
       case BASKET_STATE_RECOVERY_REBUILD:
          return (target == BASKET_STATE_IDLE || target == BASKET_STATE_ACTIVE || target == BASKET_STATE_PENDING_FIRST_ENTRY || target == BASKET_STATE_CLOSING || target == BASKET_STATE_CLOSED);
         
      default:
         return false;
   }
}

bool CBasketManager::CreateBasket(const ENUM_POSITION_TYPE direction)
{
   if(m_has_active_basket)
   {
      m_status = "rejected: active basket exists";
      return false;
   }
   
   SBasket new_basket;
   ZeroMemory(new_basket);
   new_basket.id = GenerateBasketId();
   new_basket.symbol = m_symbol;
   new_basket.direction = direction;
   new_basket.open_time = TimeCurrent();
   new_basket.start_balance = 0.0;
   new_basket.is_active = true;
   new_basket.add_entry_count = 0;
   new_basket.peak_floating_profit = 0.0;
   new_basket.trailing_activated = false;
   new_basket.closure_reason = CLOSURE_REASON_NONE;
   new_basket.state = BASKET_STATE_PENDING_FIRST_ENTRY;
   new_basket.persistence_version = "1.0";
   
   m_active_basket = new_basket;
   m_has_active_basket = true;
   m_status = StringConcatenate("created basket ", new_basket.id);
   
   if(m_persistence != NULL)
      m_persistence.SaveBasket(m_active_basket);
   
   return true;
}

bool CBasketManager::GetActiveBasket(SBasket &basket)
{
   if(!m_has_active_basket)
      return false;
   
   basket = m_active_basket;
   return true;
}

bool CBasketManager::UpdateBasketState(const string basket_id, const ENUM_BASKET_STATE new_state)
{
   if(!m_has_active_basket || m_active_basket.id != basket_id)
   {
      m_status = "rejected: basket not found";
      return false;
   }
   
   if(!IsTransitionValid(m_active_basket.state, new_state))
   {
      m_status = StringConcatenate("rejected: invalid state transition from ", EnumToString(m_active_basket.state), " to ", EnumToString(new_state));
      return false;
   }
   
   m_active_basket.state = new_state;
   m_status = StringConcatenate("state updated to ", EnumToString(new_state));
   
   if(new_state == BASKET_STATE_CLOSED)
   {
      m_has_active_basket = false;
      m_active_basket.is_active = false;
   }
   
   if(m_persistence != NULL)
      m_persistence.SaveBasket(m_active_basket);
   
   return true;
}

bool CBasketManager::CloseBasket(const string basket_id, const ENUM_CLOSURE_REASON reason)
{
   if(!m_has_active_basket || m_active_basket.id != basket_id)
   {
      m_status = "rejected: basket not found";
      return false;
   }
   
   if(m_active_basket.state == BASKET_STATE_CLOSING || m_active_basket.state == BASKET_STATE_CLOSED)
   {
      m_status = "rejected: basket already closing or closed";
      return false;
   }
   
   m_active_basket.closure_reason = reason;
   
   bool result = UpdateBasketState(basket_id, BASKET_STATE_CLOSING);
   if(result)
      m_status = StringConcatenate("closing basket, reason=", EnumToString(reason));
   
   return result;
}

bool CBasketManager::AddEntry(const string basket_id)
{
   if(!m_has_active_basket || m_active_basket.id != basket_id)
   {
      m_status = "rejected: basket not found";
      return false;
   }
   
   if(m_active_basket.state != BASKET_STATE_ACTIVE && m_active_basket.state != BASKET_STATE_TRAILING_ACTIVE)
   {
      m_status = "rejected: basket not in add-entry state";
      return false;
   }
   
   m_active_basket.add_entry_count++;
   m_status = StringConcatenate("add entry recorded, total=", IntegerToString(m_active_basket.add_entry_count));
   
   if(m_persistence != NULL)
      m_persistence.SaveBasket(m_active_basket);
   
   return true;
}

bool CBasketManager::ReconstructFromPositions()
{
   if(m_has_active_basket)
   {
      m_status = "rejected: active basket already exists";
      return false;
   }
   
   SPosition positions[];
   int count = 0;
   
   if(!m_persistence.LoadPositions(positions, count))
   {
      m_status = "rejected: failed to load positions";
      return false;
   }
   
   if(count <= 0)
   {
      m_status = "no positions to reconstruct";
      return false;
   }
   
   string first_basket_id = "";
   int basket_position_count = 0;
   
   for(int i = 0; i < count; i++)
   {
      if(positions[i].is_active && positions[i].basket_id != "")
      {
         if(first_basket_id == "")
            first_basket_id = positions[i].basket_id;
         
         if(positions[i].basket_id == first_basket_id)
            basket_position_count++;
      }
   }
   
   if(first_basket_id == "" || basket_position_count == 0)
   {
      m_status = "no active basket positions found";
      return false;
   }
   
   SBasket reconstructed;
   if(!m_persistence.LoadBasket(first_basket_id, reconstructed))
   {
      m_status = "rejected: failed to load basket from persistence";
      return false;
   }
   
   reconstructed.state = BASKET_STATE_RECOVERY_REBUILD;
   reconstructed.is_active = true;
   
   m_active_basket = reconstructed;
   m_has_active_basket = true;
   m_status = StringConcatenate("reconstructed basket from ", IntegerToString(basket_position_count), " positions");
   
   return true;
}

bool CBasketManager::ReconstructFromPersistence()
{
   if(m_has_active_basket)
   {
      m_status = "rejected: active basket already exists";
      return false;
   }
   
   string basket_ids[];
   int count = 0;
   
   if(!m_persistence.ListBaskets(basket_ids, count))
   {
      m_status = "rejected: failed to list baskets";
      return false;
   }
   
   string active_id = "";
   for(int i = 0; i < count; i++)
   {
      SBasket b;
      if(m_persistence.LoadBasket(basket_ids[i], b))
      {
         if(b.is_active && (b.state == BASKET_STATE_ACTIVE || b.state == BASKET_STATE_TRAILING_ACTIVE || b.state == BASKET_STATE_CLOSING || b.state == BASKET_STATE_PENDING_FIRST_ENTRY || b.state == BASKET_STATE_RECOVERY_REBUILD))
         {
            active_id = basket_ids[i];
            break;
         }
      }
   }
   
   if(active_id == "")
   {
      m_status = "no active basket found in persistence";
      return false;
   }
   
   SBasket reconstructed;
   if(!m_persistence.LoadBasket(active_id, reconstructed))
   {
      m_status = "rejected: failed to load active basket";
      return false;
   }
   
   reconstructed.state = BASKET_STATE_RECOVERY_REBUILD;
   
   m_active_basket = reconstructed;
   m_has_active_basket = true;
   m_status = StringConcatenate("reconstructed basket from persistence: ", active_id);
   
   return true;
}

bool CBasketManager::SetStartBalance(const string basket_id, const double balance)
{
   if(!m_has_active_basket || m_active_basket.id != basket_id)
   {
      m_status = "rejected: basket not found";
      return false;
   }
   
   m_active_basket.start_balance = balance;
   m_status = StringConcatenate("start balance set to ", DoubleToString(balance));
   
   if(m_persistence != NULL)
      m_persistence.SaveBasket(m_active_basket);
   
   return true;
}

string CBasketManager::GetDiagnostics()
{
   return StringConcatenate("basket=", (m_has_active_basket ? m_active_basket.id : "none"), " state=", (m_has_active_basket ? EnumToString(m_active_basket.state) : "n/a"), " status=", m_status);
}

int CBasketManager::GetActiveBasketCount()
{
   return (m_has_active_basket ? 1 : 0);
}

#endif // BASKETMANAGER_MQH_GUARD
