import os 
from fastapi import FastAPI, HTTPException 
  
app = FastAPI(title="App Suporte") 
  
  
def simulated_failure(): 
    return ( 
        os.getenv("SIMULATE_FAILURE", "false").lower() 
        == "true" 
    ) 
  
  
@app.get("/health") 
def health(): 
    return {"status": "alive"} 
  
  
@app.get("/ready") 
def ready(): 
    if simulated_failure(): 
        raise HTTPException( 
            status_code=503, 
            detail="Dependency unavailable" 
        )
    return {"status": "ready"} 
  
  
@app.get("/api/status") 
def status(): 
    if simulated_failure(): 
        raise HTTPException( 
            status_code=503, 
            detail="Service unavailable" 
        ) 
    return { 
        "status": "ok", 
        "version": os.getenv("APP_VERSION", "unknown"), 
        "environment": os.getenv("APP_ENV", "development") 
    } 