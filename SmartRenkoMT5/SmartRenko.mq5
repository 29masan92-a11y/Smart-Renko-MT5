//+------------------------------------------------------------------+
//| Smart Renko for MT5 - EA Entry Point                             |
//+------------------------------------------------------------------+
#property copyright "Smart Renko MT5"
#property version   "1.00"
#property strict

#include "Core/CoreModules.mqh"
#include "Core/ModuleImplementations.mqh"

//--- Global handles
CCoreOrchestrator*     g_orchestrator = NULL;
CGuiLayer*             g_gui = NULL;
CVpsRunner*            g_vps = NULL;
CNotificationManager*  g_notifier = NULL;
CReportingEngine*      g_reporter = NULL;
CPresetProfileManager* g_presets = NULL;

//--- Configuration
input ENUM_TRADING_MODE  InpTradingMode        = TRADING_MODE_FULL_AUTO;
input string             InpSymbol             = "";
input long               InpMagicNumber        = 123456;
input bool               InpEnableGui          = true;
input bool               InpEnableVps          = false;
input bool               InpEnableNotifications = true;
input bool               InpEnableReporting    = true;
input string             InpProfileName        = "Default";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   string symbol = InpSymbol;
   if(symbol == "" || symbol == "0")
      symbol = _Symbol;

   g_orchestrator = new CCoreOrchestrator();
   if(g_orchestrator == NULL)
   {
      Print("FATAL: Failed to allocate CoreOrchestrator");
      return(INIT_FAILED);
   }

   bool init_ok = g_orchestrator.Init(symbol, InpMagicNumber, InpTradingMode);
   if(!init_ok)
   {
      Print("FATAL: CoreOrchestrator initialization failed");
      delete g_orchestrator;
      g_orchestrator = NULL;
      return(INIT_FAILED);
   }

   if(InpEnableGui)
   {
      g_gui = new CGuiLayer();
      if(g_gui != NULL)
      {
         g_gui.OnInit(ChartID(), 0);
         g_orchestrator.SetGuiLayer(g_gui);
      }
   }

   if(InpEnableNotifications)
   {
      g_notifier = new CNotificationManager();
      if(g_notifier != NULL)
      {
         g_notifier.OnInit(true, true, true);
         g_orchestrator.SetNotificationManager(g_notifier);
      }
   }

   if(InpEnableReporting)
   {
      g_reporter = new CReportingEngine();
      if(g_reporter != NULL)
      {
         string report_path = "Reports";
         g_reporter.OnInit(report_path);
         g_orchestrator.SetReportingEngine(g_reporter);
      }
   }

   if(InpEnableVps)
   {
      g_vps = new CVpsRunner();
      if(g_vps != NULL)
      {
         g_vps.OnInit(symbol, InpMagicNumber);
         g_orchestrator.SetVpsRunner(g_vps);
         g_vps.Start();
      }
   }

   g_presets = new CPresetProfileManager();
   if(g_presets != NULL)
   {
      g_presets.OnInit("Profiles");
      g_orchestrator.SetPresetManager(g_presets);
   }

   EventSetTimer(1);

   Print("Smart Renko MT5 initialized. Symbol=", symbol, " Magic=", InpMagicNumber, " Mode=", EnumToString(InpTradingMode));
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();

   if(g_vps != NULL)
   {
      g_vps.Stop();
      g_vps.OnDeinit();
      delete g_vps;
      g_vps = NULL;
   }

   if(g_gui != NULL)
   {
      g_gui.OnDeinit();
      delete g_gui;
      g_gui = NULL;
   }

   if(g_notifier != NULL)
   {
      g_notifier.OnDeinit();
      delete g_notifier;
      g_notifier = NULL;
   }

   if(g_reporter != NULL)
   {
      g_reporter.OnDeinit();
      delete g_reporter;
      g_reporter = NULL;
   }

   if(g_presets != NULL)
   {
      g_presets.OnDeinit();
      delete g_presets;
      g_presets = NULL;
   }

   if(g_orchestrator != NULL)
   {
      g_orchestrator.Deinit();
      delete g_orchestrator;
      g_orchestrator = NULL;
   }

   Print("Smart Renko MT5 deinitialized. Reason=", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(g_orchestrator == NULL || !g_orchestrator.IsInitialized())
      return;

   g_orchestrator.OnTick();

   if(g_gui != NULL && g_gui.IsVisible())
      g_gui.Refresh();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   if(g_orchestrator == NULL || !g_orchestrator.IsInitialized())
      return;

   g_orchestrator.OnTimer();
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(g_gui != NULL)
      g_gui.OnChartEvent(id, lparam, dparam, sparam);
}

//+------------------------------------------------------------------+
//| TesterInit / TesterDeinit / TesterTrade (optional for tester)    |
//+------------------------------------------------------------------+
double OnTester()
{
   return 0.0;
}

void OnTesterInit()
{
}

void OnTesterDeinit()
{
}

void OnTesterTrade()
{
}
