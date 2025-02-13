/* ----------------------------------------------------------------------------
 * This file was automatically generated by SWIG (http://www.swig.org).
 * Version 3.0.12
 *
 * Do not make changes to this file unless you know what you are doing--modify
 * the SWIG interface file instead.
 * ----------------------------------------------------------------------------- */

package com.dgmpp;

public class Capacitor {
  private transient long swigCPtr;
  protected transient boolean swigCMemOwn;

  protected Capacitor(long cPtr, boolean cMemoryOwn) {
    swigCMemOwn = cMemoryOwn;
    swigCPtr = cPtr;
  }

  protected static long getCPtr(Capacitor obj) {
    return (obj == null) ? 0 : obj.swigCPtr;
  }

  protected void finalize() {
    delete();
  }

  public synchronized void delete() {
    if (swigCPtr != 0) {
      if (swigCMemOwn) {
        swigCMemOwn = false;
        dgmppJNI.delete_Capacitor(swigCPtr);
      }
      swigCPtr = 0;
    }
  }

  public double capacity() {
    return dgmppJNI.Capacitor_capacity(swigCPtr, this);
  }

  public boolean isStable() {
    return dgmppJNI.Capacitor_isStable(swigCPtr, this);
  }

  public double stableLevel() {
    return dgmppJNI.Capacitor_stableLevel(swigCPtr, this);
  }

  public double rechargeTime() {
    return dgmppJNI.Capacitor_rechargeTime(swigCPtr, this);
  }

  public double lastsTime() {
    return dgmppJNI.Capacitor_lastsTime(swigCPtr, this);
  }

  public UnitsPerSecond use() {
    return new UnitsPerSecond(dgmppJNI.Capacitor_use(swigCPtr, this), true);
  }

  public UnitsPerSecond recharge() {
    return new UnitsPerSecond(dgmppJNI.Capacitor_recharge(swigCPtr, this), true);
  }

}
