//+------------------------------------------------------------------+
//|                                                       False2.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   8


//--- the Stochastic plot
#property indicator_label1  "Stochastic"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLightSeaGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- the Signal plot
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- set limit of the indicator values

#property indicator_minimum 0
#property indicator_maximum 100


#property indicator_label3  "Over Bought"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrRed
#property indicator_width3  1

#property indicator_label4  "Over Sold"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrGreen
#property indicator_width4  1


//--- plot ColorLine
#property indicator_label5  "OverSold - False"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrGreen // (Up to 64 colors can be specified)
#property indicator_style5 STYLE_DASHDOT
#property indicator_width5  5

//--- plot ColorLine
#property indicator_label6  "OverBought - False"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrRed // (Up to 64 colors can be specified)
#property indicator_style6 STYLE_DASHDOT
#property indicator_width6  5


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input int                  Kperiod=14;                 // the K period (the number of bars for calculation)
input int                  Dperiod=3;                 // the D period (the period of primary smoothing)
input int                  slowing=3;                 // period of final smoothing
input ENUM_MA_METHOD       ma_method=MODE_SMA;        // type of smoothing
input ENUM_STO_PRICE       price_field=STO_LOWHIGH;   // method of calculation of the Stochastic
input double oversold = 80;      // Oversold
input double overbought = 20;    // OverBought
input double reset = 35;         // Reset Value
input double GreendrawPoints = 20;   // Green Arrow Point Setting
input double ReddrawPoints = 20;   // Red Arrow Point Setting
double resetOB;
double resetOS;
//--- indicator buffers

int    handle;
string name=Symbol();
int    bars_calculated=0;
ushort   code=159;

double         StochasticBuffer[];
double         SignalBuffer[];

double         ArrowsBufferOB[];
double         ArrowsBufferOS[];

double         ColorLineBufferOB[];
double         ColorLineBufferOS[];

int crossUP = 0;
int crossDN = 0;

bool lookOS = 0;
bool lookOB = 0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   resetOS = reset;
   resetOB = 100 - reset;

   handle=iStochastic(Symbol(),PERIOD_CURRENT,Kperiod,Dperiod,slowing,ma_method,price_field);
   if(handle==INVALID_HANDLE)
     {
      PrintFormat("Failed to create handle of the iStochastic indicator for the symbol %s/%s, error code %d",
                  name,
                  EnumToString(PERIOD_CURRENT),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }

//--- indicator buffers mapping
   SetIndexBuffer(0,StochasticBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ArrowsBufferOB,INDICATOR_DATA);
   SetIndexBuffer(3,ArrowsBufferOS,INDICATOR_DATA);

   SetIndexBuffer(4,ColorLineBufferOS,INDICATOR_DATA);
   SetIndexBuffer(5,ColorLineBufferOB,INDICATOR_DATA);

   PlotIndexSetInteger(2,PLOT_ARROW,234);
   PlotIndexSetInteger(2,PLOT_ARROW_SHIFT,20);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetInteger(3,PLOT_ARROW,233);
   PlotIndexSetInteger(3,PLOT_ARROW_SHIFT,20);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);


   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);


//ArraySetAsSeries(ColorLineBufferOS,false);
//ArraySetAsSeries(ColorLineBufferOB,false);

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
//---
   int i;
//--------------------------------------------------------------------
   if(prev_calculated==0)
     {
      int limit=rates_total;

      // Print(limit);
      for(i=3; i<limit; i++)
        {
         int values_to_copy;
         //--- determine the number of values calculated in the indicator
         int calculated=BarsCalculated(handle);
         if(calculated<=0)
           {
            PrintFormat("BarsCalculated() returned %d, error code %d",calculated,GetLastError());
            return(0);
           }

         if(prev_calculated==0 || calculated!=bars_calculated || rates_total>prev_calculated+1)
           {
            if(calculated>rates_total)
               values_to_copy=rates_total;
            else
               values_to_copy=calculated;
           }
         else
           {
            values_to_copy=(rates_total-prev_calculated)+1;
           }
         if(!FillArraysFromBuffers(StochasticBuffer,SignalBuffer,handle,values_to_copy))
            return(0);


         //  Print("Signal Buffer: ", SignalBuffer[i], " Time: ", time[i]);
         if(SignalBuffer[i-3] > resetOB && SignalBuffer[i-2] < resetOB)
           {
            // Print("Over Bought Arrow Found");
            ArrowsBufferOB[i-2] = 80;
            createArrow(time[i-2],high[i-2],sell);
           }

         if(SignalBuffer[i-3] < resetOS && SignalBuffer[i-2] > resetOS)
           {
            // Print("Over Sold Arrow Found");
            ArrowsBufferOS[i-2] = 20;
            createArrow(time[i-2],low[i-2],buy);
           }


         if(crossDN == 0 && crossUP ==0)
           {
            if(StochasticBuffer[i-1] < oversold)
              {
               lookOS = true;
               lookOB = false;
              }
            if(StochasticBuffer[i-1] > overbought)
              {
               lookOB = true;
               lookOS = false;
              }
           }


         if((SignalBuffer[i-1] > resetOS && crossUP > 0) || (SignalBuffer[i-1] < resetOB && crossDN > 0))
           {
            crossUP = 0;
            lookOS= false;
            crossDN = 0;
            lookOB= false;
           }


         // OverSold Condition
         if(lookOS && StochasticBuffer[i-3] < SignalBuffer[i-3] && StochasticBuffer[i-2] > SignalBuffer[i-2])
           {
            crossUP = crossUP + 1;
           }

         if(crossUP >= 3)
           {
            for(int a = 0; a <= crossUP; a++)
              {
               // Print("3 Cross Up Found", time[i-a]);
               ColorLineBufferOS[i-a] = 1;
              }
           }


         // Over Bought false Breakout Condition
         if(lookOB && StochasticBuffer[i-3] > SignalBuffer[i-3] && StochasticBuffer[i-2] < SignalBuffer[i-2])
           {
            crossDN = crossDN + 1;
           }

         // Over Bought
         if(crossDN >= 3)
           {
            for(int a = 0; a <= crossDN; a++)
              {
               // Print("3 Cross Down Found", time[i-a]);
               ColorLineBufferOB[i-a] = 99;
              }
           }

        }
     }
   else
     {
      int limit=prev_calculated-1;
      //  --- main loop

      int values_to_copy;
      // --- determine the number of values calculated in the indicator
      int calculated=BarsCalculated(handle);
      if(calculated<=0)
        {
         PrintFormat("BarsCalculated() returned %d, error code %d",calculated,GetLastError());
         return(0);
        }

      if(prev_calculated==0 || calculated!=bars_calculated || rates_total>prev_calculated+1)
        {
         if(calculated>rates_total)
            values_to_copy=rates_total;
         else
            values_to_copy=calculated;
        }
      else
        {
         values_to_copy=(rates_total-prev_calculated)+1;
        }
      if(!FillArraysFromBuffers(StochasticBuffer,SignalBuffer,handle,values_to_copy))
         return(0);


      for(i=limit; i<rates_total && !IsStopped(); i++)
        {
         bool isNewBarHere = isNewBar();
         if(SignalBuffer[i-3] > resetOB && SignalBuffer[i-2] < resetOB)
           {
            ArrowsBufferOB[i-2] = SignalBuffer[i-2];
            createArrow(time[i-2],high[i-2],sell);
           }
         if(SignalBuffer[i-3] < resetOS && SignalBuffer[i-2] > resetOS)
           {
            // Print("Over Sold Arrow Found");

            ArrowsBufferOS[i-2] = SignalBuffer[i-2];
            createArrow(time[i-2],low[i-2],buy);
           }



         if(crossDN == 0 && crossUP ==0)
           {
            if(StochasticBuffer[i-1] < oversold)
              {
               lookOS = true;
               lookOB = false;
              }
            if(StochasticBuffer[i-1] > overbought)
              {
               lookOB = true;
               lookOS = false;
              }
           }

         // Over Sold False Breakout Condition
         if(lookOS && StochasticBuffer[i-3] < SignalBuffer[i-3] && StochasticBuffer[i-2] > SignalBuffer[i-2])
           {
            if(isNewBarHere)
              {
               crossUP = crossUP + 1;
              }
           }

         if(crossUP >= 3)
           {
            for(int a = 0; a <= crossUP; a++)
              {
               // Print("3 Cross Up Found", time[i-a]);
               ColorLineBufferOS[i-a] = 1;
              }
           }

         if(SignalBuffer[i-1] > resetOS)
           {
            crossUP = 0;
            lookOS= false;
            lookOB= false;
           }

         // Over Bough false Breakout Condition
         if(lookOB && StochasticBuffer[i-3] > SignalBuffer[i-3] && StochasticBuffer[i-2] < SignalBuffer[i-2])
           {
            if(isNewBarHere)
              {
               crossDN = crossDN + 1;
              }
           }

         // Over Bought
         if(crossDN >= 3)
           {
            for(int a = 0; a <= crossDN; a++)
              {
               //  Print("3 Cross Down Found", time[i-a]);
               ColorLineBufferOB[i-a] = 99;
              }
           }
         if(SignalBuffer[i-1] < resetOB || SignalBuffer[i-1] > resetOS)
           {
            crossUP = 0;
            crossDN = 0;
            lookOB= false;
            lookOS= false;
           }
        }
     }



   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
int IndicatorCountedMQL4(int prev_calculated)
  {
   if(prev_calculated>0)
      return(prev_calculated-1);
   if(prev_calculated==0)
      return(0);
   return(0);
  }

//+------------------------------------------------------------------+
bool FillArraysFromBuffers(double &main_buffer[],    // indicator buffer of Stochastic Oscillator values
                           double &signal_buffer[],  // indicator buffer of the signal line
                           int ind_handle,           // handle of the iStochastic indicator
                           int amount                // number of copied values
                          )
  {
//--- reset error code
   ResetLastError();
//--- fill a part of the StochasticBuffer array with values from the indicator buffer that has 0 index
   if(CopyBuffer(ind_handle,MAIN_LINE,0,amount,main_buffer)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iStochastic indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(false);
     }
//--- fill a part of the SignalBuffer array with values from the indicator buffer that has index 1
   if(CopyBuffer(ind_handle,SIGNAL_LINE,0,amount,signal_buffer)<0)
     {

      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iStochastic indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(false);
     }

//--- everything is fine
   return(true);
  }
//+------------------------------------------------------------------+
//| Indicator deinitialization function                              |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(handle!=INVALID_HANDLE)
      IndicatorRelease(handle);
//--- clear the chart after deleting the indicator

   string name = "";
   for(int i = ObjectsTotal(0)-1; i >= 0; i--)
     {
      name = ObjectName(0,i);
      if((StringFind(name,sell,0) >= 0  || StringFind(name,buy,0) >= 0)&& ObjectGetInteger(0,name,OBJPROP_TYPE) == OBJ_ARROW)
        {
         ObjectDelete(0,name);
        }
     }
   Comment("");
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool isNewBar()
  {
   static datetime newBar;
   datetime curbar = iTime(Symbol(),PERIOD_CURRENT,0);
   if(newBar!=curbar)
     {
      // Print("New Minute Bar: ", curbar);
      newBar=curbar;

      return (true);
     }
   else
     {
      return (false);
     }
  }
//+------------------------------------------------------------------+
const string buy = "Buy",sell = "Sell";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createArrow(datetime time, double price, string type)
  {
   if(type == buy)
     {
      price = price - GreendrawPoints*Point()*10;

     }
   else
     {
      price = price + ReddrawPoints*Point()*10;
     }
   string objName = type+IntegerToString(time);
   if(!ObjectCreate(0,objName,OBJ_ARROW,0,time,price))
     {
      Print("Error in Creating Arrow "+type, GetLastError());
     }
   else
     {
      if(type == buy)
        {

         ObjectSetInteger(0,objName,OBJPROP_COLOR,clrGreen);
         ObjectSetInteger(0,objName,OBJPROP_ARROWCODE,233);
        }
      else
        {

         ObjectSetInteger(0,objName,OBJPROP_COLOR,clrRed);
         ObjectSetInteger(0,objName,OBJPROP_ARROWCODE,234);
        }
     }
  }
//+------------------------------------------------------------------+
