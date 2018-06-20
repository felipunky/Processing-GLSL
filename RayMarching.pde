PShader shader;
PShader shaderOne;

boolean fillVal;
boolean cam;

void keyPressed() {
  if (key == '2') 
  {
    
    fillVal = true;
    println( "fillVal = " + fillVal );
    
  } 
  else if (key == '1') 
  {
      fillVal = false;
      println( "fillVal = " + fillVal );
      
      } 
      else
      {
        
        fillVal = false;
      
    }
    
}

void setup() {
  size(800, 450, P2D);
  noStroke();
  
  //shader = loadShader("SDFOne.glsl");  
  shader = loadShader("SDF.glsl");
  shaderOne = loadShader("RayMarching.glsl");

}

void draw() {
  shader.set("iResolution", float(width), float(height));
  shader.set("iMouse", float(mouseX), float(mouseY));
  shader.set("iTime", millis() / 1000.0);
  shaderOne.set("iResolution", float(width), float(height));
  shaderOne.set("iMouse", float(mouseX), float(mouseY));
  shaderOne.set("iTime", millis() / 1000.0);
  shader(shader);

  if( fillVal == true )
  {
  
    resetShader();
    shader(shaderOne);
    
  }
  
  rect(0, 0, width, height);
  
  //println( frameRate );
}