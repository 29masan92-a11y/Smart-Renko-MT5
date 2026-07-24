//+------------------------------------------------------------------+
//| Notification Manager - Concrete Placeholder                      |
//+------------------------------------------------------------------+
#ifndef NOTIFICATIONMANAGER_MQH_GUARD
#define NOTIFICATIONMANAGER_MQH_GUARD

#include "Types.mqh"
#include "Interfaces.mqh"

class CNotificationManager : public INotificationManager
{
private:
   bool                    m_push_enabled;
   bool                    m_email_enabled;
   bool                    m_sound_enabled;
   bool                    m_initialized;

public:
   CNotificationManager();
   virtual ~CNotificationManager();
   
   virtual bool OnInit(const bool enable_push, const bool enable_email, const bool enable_sound);
   virtual void OnDeinit();
   
   virtual bool Send(const string subject, const string message);
   virtual bool SendBasketEvent(const string basket_id, const ENUM_BASKET_STATE state, const string details);
   virtual bool SendRiskAlert(const string alert_type, const string message);
   virtual bool SendTradeEvent(const string symbol, const ENUM_BROKER_ORDER_TYPE type, const double volume, const double price);
   virtual bool IsEnabled();
};

//+------------------------------------------------------------------+
//| CNotificationManager Implementation                             |
//+------------------------------------------------------------------+
CNotificationManager::CNotificationManager() : m_push_enabled(false),
   m_email_enabled(false),
   m_sound_enabled(false),
   m_initialized(false)
{
}

CNotificationManager::~CNotificationManager()
{
   OnDeinit();
}

bool CNotificationManager::OnInit(const bool enable_push, const bool enable_email, const bool enable_sound)
{
   m_push_enabled = enable_push;
   m_email_enabled = enable_email;
   m_sound_enabled = enable_sound;
   m_initialized = true;
   return true;
}

void CNotificationManager::OnDeinit()
{
   m_initialized = false;
}

bool CNotificationManager::Send(const string subject, const string message)
{
   return false;
}

bool CNotificationManager::SendBasketEvent(const string basket_id, const ENUM_BASKET_STATE state, const string details)
{
   return false;
}

bool CNotificationManager::SendRiskAlert(const string alert_type, const string message)
{
   return false;
}

bool CNotificationManager::SendTradeEvent(const string symbol, const ENUM_BROKER_ORDER_TYPE type, const double volume, const double price)
{
   return false;
}

bool CNotificationManager::IsEnabled()
{
   return (m_push_enabled || m_email_enabled || m_sound_enabled);
}

#endif // NOTIFICATIONMANAGER_MQH_GUARD
