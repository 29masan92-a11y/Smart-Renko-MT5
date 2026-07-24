//+------------------------------------------------------------------+
//| Trailing Manager - Concrete Implementation                        |
//+------------------------------------------------------------------+
#ifndef TRAILINGMANAGER_MQH_GUARD
#define TRAILINGMANAGER_MQH_GUARD

#include "Types.mqh"
#include "Interfaces.mqh"
#include "PersistenceLayer.mqh"

class CTrailingManager : public ITrailingManager
   void SetPersistenceLayer(IPersistenceLayer* persistence) { m_persistence = persistence; }
{
private:
    string                  m_basket_id;
    double                  m_start_balance;
    double                  m_threshold;
    double                  m_trail_amount;
    bool                    m_active;
    double                  m_peak_profit;
    string                  m_config_json;
    bool                    m_initialized;
    IPersistenceLayer*      m_persistence;

    bool                    m_include_commission;
    bool                    m_include_swap;
    int                     m_min_eval_seconds;
    datetime                m_last_eval_time;
    double                  m_last_eval_profit;
    int                     m_consecutive_drops;
    int                     m_drops_to_close;

    void                   ParseConfig(const string config_json);
    bool                   IsRapidTick(const double current_profit) const;

public:
    CTrailingManager();
    virtual ~CTrailingManager();

    virtual bool OnInit(const string basket_id, const double start_balance, const double threshold, const double trail_amount, const string config_json);
    virtual void OnDeinit();

    virtual bool Evaluate(const double current_floating_profit);
    virtual bool IsActive();
    virtual double GetPeakProfit();
    virtual bool RestoreState(const double peak_profit, const bool activated);
    virtual string GetDiagnostics();

    virtual void LoadParameters(const string config_json);
    virtual bool PersistState();
    virtual bool RestoreFromPersistence(const string basket_id);
    virtual void HandlePartialClose(const double remaining_profit);
    virtual double GetAdjustedProfit(const double raw_profit) const;
};

//+------------------------------------------------------------------+
//| CTrailingManager Implementation                                  |
//+------------------------------------------------------------------+
CTrailingManager::CTrailingManager() : m_basket_id(""),
    m_start_balance(0.0),
    m_threshold(0.0),
    m_trail_amount(0.0),
    m_active(false),
    m_peak_profit(0.0),
    m_initialized(false),
    m_persistence(NULL),
    m_include_commission(true),
    m_include_swap(true),
    m_min_eval_seconds(1),
    m_last_eval_time(0),
    m_last_eval_profit(0.0),
    m_consecutive_drops(0),
    m_drops_to_close(2)
{
}

CTrailingManager::~CTrailingManager()
{
    OnDeinit();
}

void CTrailingManager::ParseConfig(const string config_json)
{
    m_include_commission = true;
    m_include_swap = true;
    m_min_eval_seconds = 1;
    m_drops_to_close = 2;

    if(config_json == "" || config_json == "0")
        return;

    string parts[];
    StringSplit(config_json, ';', parts);

    for(int i = 0; i < ArraySize(parts); i++)
    {
        if(parts[i] == "") continue;

        string kv[];
        StringSplit(parts[i], '=', kv);

        if(ArraySize(kv) < 2) continue;

        string key = StringTrim(kv[0]);
        string value = StringTrim(kv[1]);

        if(key == "include_commission")
            m_include_commission = (value == "1" || value == "true");
        else if(key == "include_swap")
            m_include_swap = (value == "1" || value == "true");
        else if(key == "min_eval_seconds")
            m_min_eval_seconds = StringToInteger(value);
        else if(key == "drops_to_close")
            m_drops_to_close = StringToInteger(value);
    }
}

bool CTrailingManager::OnInit(const string basket_id, const double start_balance, const double threshold, const double trail_amount, const string config_json)
{
    m_basket_id = basket_id;
    m_start_balance = start_balance;
    m_threshold = threshold;
    m_trail_amount = trail_amount;
    m_config_json = config_json;
    m_active = false;
    m_peak_profit = 0.0;
    m_last_eval_time = 0;
    m_last_eval_profit = 0.0;
    m_consecutive_drops = 0;
    m_initialized = true;

    ParseConfig(config_json);

    if(m_persistence != NULL)
        m_persistence->SaveTrailingState(basket_id, 0.0, false);

    return true;
}

void CTrailingManager::OnDeinit()
{
    m_initialized = false;
    m_persistence = NULL;
    m_active = false;
}

void CTrailingManager::LoadParameters(const string config_json)
{
    m_config_json = config_json;
    ParseConfig(config_json);
}

double CTrailingManager::GetAdjustedProfit(const double raw_profit) const
{
    if(m_include_commission && m_include_swap)
        return raw_profit;

    double adjusted = raw_profit;

    if(!m_include_commission && !m_include_swap)
    {
        return adjusted;
    }

    return adjusted;
}

bool CTrailingManager::IsRapidTick(const double current_profit) const
{
    if(m_min_eval_seconds <= 0)
        return false;

    datetime now = TimeCurrent();
    if(now < m_last_eval_time + m_min_eval_seconds)
        return true;

    return false;
}

bool CTrailingManager::Evaluate(const double current_floating_profit)
{
    if(!m_initialized) return false;

    double adjusted_profit = GetAdjustedProfit(current_floating_profit);

    if(!m_active)
    {
        if(adjusted_profit >= m_threshold)
        {
            m_active = true;
            m_peak_profit = adjusted_profit;
            m_last_eval_time = TimeCurrent();
            m_last_eval_profit = adjusted_profit;
            m_consecutive_drops = 0;

            if(m_persistence != NULL)
                m_persistence->SaveTrailingState(m_basket_id, m_peak_profit, true);
        }
        return false;
    }

    if(IsRapidTick(adjusted_profit))
        return false;

    if(adjusted_profit > m_peak_profit)
    {
        m_peak_profit = adjusted_profit;
        m_consecutive_drops = 0;
    }
    else if(adjusted_profit < m_last_eval_profit)
    {
        m_consecutive_drops++;
    }
    else
    {
        if(m_consecutive_drops > 0)
            m_consecutive_drops--;
    }

    m_last_eval_time = TimeCurrent();
    m_last_eval_profit = adjusted_profit;

    if(m_consecutive_drops >= m_drops_to_close)
    {
        if(adjusted_profit <= (m_peak_profit - m_trail_amount))
        {
            if(m_persistence != NULL)
                m_persistence->SaveTrailingState(m_basket_id, m_peak_profit, false);

            return true;
        }
    }

    return false;
}

bool CTrailingManager::IsActive()
{
    return m_active;
}

double CTrailingManager::GetPeakProfit()
{
    return m_peak_profit;
}

bool CTrailingManager::RestoreState(const double peak_profit, const bool activated)
{
    if(!m_initialized) return false;

    m_peak_profit = peak_profit;
    m_active = activated;
    m_last_eval_time = TimeCurrent();
    m_last_eval_profit = peak_profit;
    m_consecutive_drops = 0;

    if(m_persistence != NULL)
        m_persistence->SaveTrailingState(m_basket_id, m_peak_profit, m_active);

    return true;
}

void CTrailingManager::HandlePartialClose(const double remaining_profit)
{
    if(!m_initialized || !m_active) return;

    double adjusted = GetAdjustedProfit(remaining_profit);

    if(adjusted < m_peak_profit)
    {
        m_peak_profit = adjusted;
        m_consecutive_drops = 0;
    }

    m_last_eval_profit = adjusted;
    m_last_eval_time = TimeCurrent();

    if(m_persistence != NULL)
        m_persistence->SaveTrailingState(m_basket_id, m_peak_profit, m_active);
}

bool CTrailingManager::PersistState()
{
    if(!m_initialized || m_persistence == NULL)
        return false;

    return m_persistence->SaveTrailingState(m_basket_id, m_peak_profit, m_active);
}

bool CTrailingManager::RestoreFromPersistence(const string basket_id)
{
    if(m_persistence == NULL)
        return false;

    double peak = 0.0;
    bool activated = false;

    if(!m_persistence->LoadTrailingState(basket_id, peak, activated))
        return false;

    m_basket_id = basket_id;
    m_peak_profit = peak;
    m_active = activated;
    m_last_eval_time = TimeCurrent();
    m_last_eval_profit = peak;
    m_consecutive_drops = 0;

    return true;
}

string CTrailingManager::GetDiagnostics()
{
    return StringConcatenate("trailing: active=", (m_active ? "yes" : "no"), " peak=", DoubleToString(m_peak_profit), " threshold=", DoubleToString(m_threshold), " trail=", DoubleToString(m_trail_amount));
}

#endif // TRAILINGMANAGER_MQH_GUARD
