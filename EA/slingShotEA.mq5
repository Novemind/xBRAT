//+------------------------------------------------------------------+
//|                                                  slingShotEA.mq5 |
//|                                    Copyright 2023, Novemind inc. |
//|                                         https://www.novemind.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Novemind inc."
#property link      "https://www.novemind.com"
#property version   "1.00"


#include <Trade\Trade.mqh>
CTrade trade;

input string               str1        = "<><><><><> General Settings <><><><><>";              // _
input double               lotsize     = 0.01;                                                  // Lot Size
input int                  magic_no    = 123;                                                   // Magic Number
input int                  rectCandles = 10;                                                    // Shading Candles

const string buyFibo = "buyFibo",sellFibo = "sellFibo";

int falseStoHandler;
double overBoughtSell[],overSoughtBuy[];
bool sellDrawn = false, buyDrawn = false;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(magic_no);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_IOC);
   trade.LogLevel(LOG_LEVEL_ALL);
   trade.SetAsyncMode(false);

   falseStoHandler = iCustom(Symbol(),PERIOD_CURRENT,indicatorName);
   if(falseStoHandler == INVALID_HANDLE)
      Print("Invalid Handle: ",GetLastError());

   ArraySetAsSeries(overSoughtBuy,true);
   ArraySetAsSeries(overBoughtSell,true);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   ObjectsDeleteAll(0);
  }
string indicatorName = "false2v2";
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---




   if(newBar())
     {
      if(CopyBuffer(falseStoHandler,2,0,500,overBoughtSell) < 0)
         Print("Error in Copying Buffer ",GetLastError());
      if(CopyBuffer(falseStoHandler,3,0,500,overSoughtBuy) < 0)
         Print("Error in Copying Buffer ",GetLastError());

      if(overBoughtSell[2] != 0 && overBoughtSell[2] != EMPTY_VALUE && sellDrawn == false)
        {
         Print("Sell: ",overBoughtSell[2]);
         double highValue = 0, lowValue = 0;

         for(int i = 3; i < Bars(Symbol(),PERIOD_CURRENT); i++)
           {
            if(overSoughtBuy[i] != 0 && overSoughtBuy[i] != EMPTY_VALUE && highValue == 0 && lowValue == 0)
              {
               int highIndex = iHighest(Symbol(),PERIOD_CURRENT,MODE_HIGH,i,0);
               highValue = iHigh(Symbol(),PERIOD_CURRENT,highIndex);
               Print("High Value: ",highValue," Time: ",iTime(Symbol(),PERIOD_CURRENT,highIndex));
              }
            if(overBoughtSell[i] != 0 && overBoughtSell[i] != EMPTY_VALUE && highValue > 0 && lowValue == 0)
              {
               int lowIndex = iLowest(Symbol(),PERIOD_CURRENT,MODE_LOW,i,0);
               lowValue = iLow(Symbol(),PERIOD_CURRENT,lowIndex);
               Print("Low Value: ",lowValue," Time: ",iTime(Symbol(),PERIOD_CURRENT,lowIndex));
               drawFibonacci(POSITION_TYPE_SELL,highValue,lowValue);
               buyDrawn = false;
               sellDrawn = true;
               break;
              }
           }
        }

      if(overSoughtBuy[2] != 0 && overSoughtBuy[2] != EMPTY_VALUE && buyDrawn == false)
        {
         Print("Buy: ",overSoughtBuy[2]);
         double highValue = 0, lowValue = 0;

         for(int i = 3; i < Bars(Symbol(),PERIOD_CURRENT); i++)
           {
            if(overBoughtSell[i] != 0 && overBoughtSell[i] != EMPTY_VALUE && highValue == 0 && lowValue == 0)
              {
               int lowIndex = iLowest(Symbol(),PERIOD_CURRENT,MODE_LOW,i,0);
               lowValue = iLow(Symbol(),PERIOD_CURRENT,lowIndex);
               Print("Low Value: ",lowValue," Time: ",iTime(Symbol(),PERIOD_CURRENT,lowIndex));
              }

            if(overSoughtBuy[i] != 0 && overSoughtBuy[i] != EMPTY_VALUE && highValue == 0 && lowValue > 0)
              {
               int highIndex = iHighest(Symbol(),PERIOD_CURRENT,MODE_HIGH,i,0);
               highValue = iHigh(Symbol(),PERIOD_CURRENT,highIndex);
               Print("High Value: ",highValue," Time: ",iTime(Symbol(),PERIOD_CURRENT,highIndex));
               drawFibonacci(POSITION_TYPE_BUY,highValue,lowValue);
               buyDrawn = true;
               sellDrawn = false;
               break;
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool newBar()
  {
//--- memorize the time of opening of the last bar in the static variable
   static datetime last_time=0;
//--- current time
   datetime lastbar_time=(datetime)SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);
   if(last_time!=lastbar_time)
     {
      //--- memorize the time and return true
      last_time=lastbar_time;
      Print(".... NewBar .... ",last_time);
      return(true);
     }
//--- if we passed to this line, then the bar is not new; return false
   return(false);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawFibonacci(ENUM_POSITION_TYPE type,double high, double low)
  {
   string name = "";

   if(type == POSITION_TYPE_SELL)
     {
      name = sellFibo+IntegerToString(TimeCurrent());
      if(ObjectFind(0,sellFibo) < 0)
        {
         if(!ObjectCreate(0,name,OBJ_FIBO,0,iTime(Symbol(),PERIOD_CURRENT,1),high,iTime(Symbol(),PERIOD_CURRENT,0),low))
           {
            Print("Failed to create \"Fibonacci Retracement\"! Error code = ",GetLastError());
           }
         double values[13] = {1,0.786,0.618,0.5,0.382,0.236,0,-0.1,-0.27,-0.62,-0.76,-1.62,-1.86};
         double values_1[13] = {100,78.6,61.8,50,3.82,23.6,0,110,127,162,176,262,286};
         ObjectSetInteger(0,name,OBJPROP_BGCOLOR,clrRed);
         ObjectSetInteger(0,name,OBJPROP_COLOR,clrRed);
         ObjectSetInteger(0,name,OBJPROP_LEVELS,ArraySize(values));
         for(int i=0; i < ArraySize(values); i++)
           {
            ObjectSetDouble(0,name,OBJPROP_LEVELVALUE,i,values[i]);
            ObjectSetInteger(0,name,OBJPROP_LEVELCOLOR,i,clrRed);
            ObjectSetInteger(0,name,OBJPROP_LEVELSTYLE,i,STYLE_SOLID);
            ObjectSetInteger(0,name,OBJPROP_LEVELWIDTH,i,1);
            ObjectSetString(0,name,OBJPROP_LEVELTEXT,i,DoubleToString(values_1[i],2));
           }
         double diff = high - low;
         createRectangle("23"+name,low+diff*0.236,low+diff*0.382,iTime(Symbol(),PERIOD_CURRENT,0),clrRed);
         createRectangle("38"+name,low+diff*0.382,low+diff*0.5,iTime(Symbol(),PERIOD_CURRENT,0),clrTomato);
         createRectangle("61"+name,low+diff*0.5,low+diff*0.618,iTime(Symbol(),PERIOD_CURRENT,0),clrLightCoral);

         createRectangle("tp1"+name,high-diff*1.1,high-diff*1.27,iTime(Symbol(),PERIOD_CURRENT,0),clrRed);
         createRectangle("tp2"+name,high-diff*1.62,high-diff*1.76,iTime(Symbol(),PERIOD_CURRENT,0),clrRed);
         createRectangle("tp3"+name,high-diff*2.62,high-diff*2.86,iTime(Symbol(),PERIOD_CURRENT,0),clrRed);
        }
     }
   else
      if(type == POSITION_TYPE_BUY)
        {
         name = buyFibo+IntegerToString(TimeCurrent());
         if(ObjectFind(0,buyFibo) < 0)
           {
            if(!ObjectCreate(0,name,OBJ_FIBO,0,iTime(Symbol(),PERIOD_CURRENT,1),low,iTime(Symbol(),PERIOD_CURRENT,0),high))
              {
               Print("Failed to create \"Fibonacci Retracement\"! Error code = ",GetLastError());
              }
            double values[13] = {0,0.236,0.382,0.5,0.618,0.786,1,-0.1,-0.27,-0.62,-0.76,-1.62,-1.86};
            double values_1[13] = {0,23.6,3.82,50,61.8,78.6,100,110,127,162,176,262,286};
            ObjectSetInteger(0,name,OBJPROP_BGCOLOR,clrGreen);
            ObjectSetInteger(0,name,OBJPROP_COLOR,clrGreen);
            ObjectSetInteger(0,name,OBJPROP_LEVELS,ArraySize(values));
            for(int i=0; i < ArraySize(values) ; i++)
              {
               ObjectSetDouble(0,name,OBJPROP_LEVELVALUE,i,values[i]);
               ObjectSetInteger(0,name,OBJPROP_LEVELCOLOR,i,clrGreen);
               ObjectSetInteger(0,name,OBJPROP_LEVELSTYLE,i,STYLE_SOLID);
               ObjectSetInteger(0,name,OBJPROP_LEVELWIDTH,i,1);
               ObjectSetString(0,name,OBJPROP_LEVELTEXT,i,DoubleToString(values_1[i],1));
              }
            double diff = high - low;
            createRectangle("23"+name,high-diff*0.236,high-diff*0.382,iTime(Symbol(),PERIOD_CURRENT,0),clrGreen);
            createRectangle("38"+name,high-diff*0.382,high-diff*0.5,iTime(Symbol(),PERIOD_CURRENT,0),clrLimeGreen);
            createRectangle("61"+name,high-diff*0.5,high-diff*0.618,iTime(Symbol(),PERIOD_CURRENT,0),clrLime);

            createRectangle("tp1"+name,low+diff*1.1,low+diff*1.27,iTime(Symbol(),PERIOD_CURRENT,0),clrGreen);
            createRectangle("tp2"+name,low+diff*1.62,low+diff*1.76,iTime(Symbol(),PERIOD_CURRENT,0),clrGreen);
            createRectangle("tp3"+name,low+diff*2.62,low+diff*2.86,iTime(Symbol(),PERIOD_CURRENT,0),clrGreen);
           }
        }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void placeBuyTrades(double buyTp,double buySL)
  {
   double Ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   if(trade.PositionOpen(Symbol(),ORDER_TYPE_BUY,lotsize,Ask,buySL,buyTp,"Buy Trade Placed"))
     {
      Print("Buy Trade Placed");
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void placeSellTrades(double sellTp,double sellSL)
  {
   double Bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);
   if(trade.PositionOpen(Symbol(),ORDER_TYPE_SELL,lotsize,Bid,sellSL,sellTp,"Sell Trade Placed"))
     {
      Print("Sell Trade PLaced ");
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createRectangle(string name, double price1, double price2,datetime time1, color clr)
  {
   datetime time2 = time1+rectCandles*PeriodSeconds(PERIOD_CURRENT);
   if(!ObjectCreate(0,name,OBJ_RECTANGLE,0,time1,price1,time2,price2))
      Print(name+" Error in Creating Object: ",GetLastError());
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_FILL,true);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
  }


//+------------------------------------------------------------------+