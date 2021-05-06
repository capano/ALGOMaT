
//+----------------------------------------------------------------------------------------------------------------------------+
//| T3A.mq5   ver 0.9 em desenvolvimento                                                                                                                 |
//| 2021 - W.Capano               																							   |
//| Baseado em https://www.technicalindicators.net/indicators-technical-analysis/150-t3-moving-average                         |
//+----------------------------------------------------------------------------------------------------------------------------+

#property description "Tillson's T3 Moving Average"
#property indicator_chart_window
#property indicator_buffers 11
#property indicator_plots   1
//--- plot T3
#property indicator_label1  "T3"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRoyalBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- parameters
input uint                 InpVolFactor      =  70;            // Volume factor (in percent)
input uint                 InpPeriod         =  20;            // Period
input ENUM_APPLIED_PRICE   InpAppliedPrice   =  PRICE_CLOSE;   // Applied price
//--- buffers
double         BufferT3[];
double         BufferEMA1[];
double         BufferAvgEMA1[];
double         BufferEMA2[];
double         BufferAvgEMA2[];
double         BufferEMA3[];
double         BufferAvgEMA3[];
double         BufferGD1[];
double         BufferAvgGD1[];
double         BufferGD2[];
double         BufferAvgGD2[];
//--- variables
double         vol_factor;
int            period_ma;
int            handle_ma;
//--- includes
#include <MovingAverages.mqh>

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set global variables
   period_ma=int(InpPeriod<2 ? 2 : InpPeriod);
   vol_factor=InpVolFactor/100.0;
//--- indicator buffers mapping
   SetIndexBuffer(0,BufferT3,INDICATOR_DATA);
   SetIndexBuffer(1,BufferEMA1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,BufferEMA2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,BufferEMA3,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,BufferAvgEMA1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,BufferAvgEMA2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,BufferAvgEMA3,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,BufferGD1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,BufferGD2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,BufferAvgGD1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,BufferAvgGD2,INDICATOR_CALCULATIONS);
//--- setting indicator parameters
   IndicatorSetString(INDICATOR_SHORTNAME,"T3 MA ("+(string)period_ma+","+DoubleToString(vol_factor*100,0)+"%)");
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
//--- setting buffer arrays as timeseries
   ArraySetAsSeries(BufferT3,true);
   ArraySetAsSeries(BufferEMA1,true);
   ArraySetAsSeries(BufferEMA2,true);
   ArraySetAsSeries(BufferEMA3,true);
   ArraySetAsSeries(BufferAvgEMA1,true);
   ArraySetAsSeries(BufferAvgEMA2,true);
   ArraySetAsSeries(BufferAvgEMA3,true);
   ArraySetAsSeries(BufferGD1,true);
   ArraySetAsSeries(BufferGD2,true);
   ArraySetAsSeries(BufferAvgGD1,true);
   ArraySetAsSeries(BufferAvgGD2,true);
//--- create MA's handles
   ResetLastError();
   handle_ma=iMA(NULL,PERIOD_CURRENT,period_ma,0,MODE_EMA,InpAppliedPrice);
   if(handle_ma==INVALID_HANDLE)
     {
      Print("The iMA(",(string)period_ma,") by ",EnumToString(InpAppliedPrice)," object was not created: Error ",GetLastError());
      return INIT_FAILED;
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- Number of calculated bars - Check and calc
   if(rates_total<fmax(period_ma,4)) return 0;
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-1;
      ArrayInitialize(BufferT3,EMPTY_VALUE);
      ArrayInitialize(BufferEMA1,0);
      ArrayInitialize(BufferEMA2,0);
      ArrayInitialize(BufferEMA3,0);
      ArrayInitialize(BufferAvgEMA1,0);
      ArrayInitialize(BufferAvgEMA2,0);
      ArrayInitialize(BufferAvgEMA3,0);
      ArrayInitialize(BufferGD1,0);
      ArrayInitialize(BufferGD2,0);
      ArrayInitialize(BufferAvgGD1,0);
      ArrayInitialize(BufferAvgGD2,0);
     }
//--- Data prep
   int count=(limit>1 ? rates_total : 1),copied=0;
   copied=CopyBuffer(handle_ma,0,0,count,BufferEMA1);    // EMA1
   if(copied!=count) return 0;
  
//--- Indicator calc
   if(ExponentialMAOnBuffer(rates_total,prev_calculated,0,period_ma,BufferEMA1,BufferAvgEMA1)==0)
      return 0;
   for(int i=limit; i>=0 && !IsStopped(); i--)           // GD1
      BufferGD1[i]=(1.0+vol_factor)*BufferEMA1[i]-vol_factor*BufferAvgEMA1[i];

   if(ExponentialMAOnBuffer(rates_total,prev_calculated,0,period_ma,BufferGD1,BufferEMA2)==0)
      return 0;                                          // EMA2

   if(ExponentialMAOnBuffer(rates_total,prev_calculated,0,period_ma,BufferEMA2,BufferAvgEMA2)==0)
      return 0;                                          
   for(int i=limit; i>=0 && !IsStopped(); i--)           // GD2
      BufferGD2[i]=(1.0+vol_factor)*BufferEMA2[i]-vol_factor*BufferAvgEMA2[i];

   if(ExponentialMAOnBuffer(rates_total,prev_calculated,0,period_ma,BufferGD2,BufferEMA3)==0)
      return 0;                                          // EMA3
  
   if(ExponentialMAOnBuffer(rates_total,prev_calculated,0,period_ma,BufferEMA3,BufferAvgEMA3)==0)
      return 0;                                          
   for(int i=limit; i>=0 && !IsStopped(); i--)           // T3
      BufferT3[i]=(1.0+vol_factor)*BufferEMA3[i]-vol_factor*BufferAvgEMA3[i];

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

  