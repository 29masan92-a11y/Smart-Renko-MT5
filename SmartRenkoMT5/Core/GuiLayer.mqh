//+------------------------------------------------------------------+
//| GUI Layer - Concrete Placeholder                                 |
//+------------------------------------------------------------------+
#ifndef GUILAYER_MQH_GUARD
#define GUILAYER_MQH_GUARD

#include "Types.mqh"
#include "Interfaces.mqh"

class CGuiLayer : public IGuiLayer
{
private:
   long                    m_chart_id;
   int                     m_subwin;
   bool                    m_visible;
   bool                    m_initialized;

public:
   CGuiLayer();
   virtual ~CGuiLayer();
   
   virtual bool OnInit(const long chart_id, const int subwin);
   virtual void OnDeinit();
   
   virtual void UpdateState(const ENUM_BASKET_STATE state, const string basket_id);
   virtual void UpdateSignalStrength(const double strength, const ENUM_SIGNAL_DIRECTION direction);
   virtual void UpdateBasketMetrics(const SBasketMetrics &metrics);
   virtual void UpdateRiskStatus(const SRiskMetrics &metrics);
   virtual bool ProcessUserCommand(const string command, string &response);
   virtual bool IsVisible();
   virtual void Show();
   virtual void Hide();
   virtual void Refresh();
};

//+------------------------------------------------------------------+
//| CGuiLayer Implementation                                         |
//+------------------------------------------------------------------+
CGuiLayer::CGuiLayer() : m_chart_id(0),
   m_subwin(0),
   m_visible(false),
   m_initialized(false)
{
}

CGuiLayer::~CGuiLayer()
{
   OnDeinit();
}

bool CGuiLayer::OnInit(const long chart_id, const int subwin)
{
   m_chart_id = chart_id;
   m_subwin = subwin;
   m_initialized = true;
   return true;
}

void CGuiLayer::OnDeinit()
{
   m_initialized = false;
}

void CGuiLayer::UpdateState(const ENUM_BASKET_STATE state, const string basket_id)
{
}

void CGuiLayer::UpdateSignalStrength(const double strength, const ENUM_SIGNAL_DIRECTION direction)
{
}

void CGuiLayer::UpdateBasketMetrics(const SBasketMetrics &metrics)
{
}

void CGuiLayer::UpdateRiskStatus(const SRiskMetrics &metrics)
{
}

bool CGuiLayer::ProcessUserCommand(const string command, string &response)
{
   response = "GUI stub";
   return false;
}

bool CGuiLayer::IsVisible()
{
   return m_visible;
}

void CGuiLayer::Show()
{
   m_visible = true;
}

void CGuiLayer::Hide()
{
   m_visible = false;
}

void CGuiLayer::Refresh()
{
}

#endif // GUILAYER_MQH_GUARD
