PShader shader;
PShader shaderOne;
PImage noise;

boolean fillVal = false;
boolean cam = false;

void keyPressed() {
  if (key == '1') 
  {
    
    fillVal = false;
    println( "fillVal = " + fillVal );
    
  } 
  else if (key == '2') 
  {
      fillVal = true;
      println( "fillVal = " + fillVal );
      
  } 
    
  if( cam == false )
  {
  
    if( key == 'c' || key == 'C' )
    {
    
      cam = true;
      println( "Cam = " + cam );
    
    }
  
  }
  
  else if( cam == true )
  {
  
    if( key == 'c' || key == 'C' )
    {
    
      cam = false;
      println( "Cam = " + cam );
    
    }
  
  }
    
}

void setup() {
  size(800, 450, P2D);
  noStroke();
  
  noise = loadImage("Noise.png");
  textureWrap(Texture.REPEAT);
  //shader = loadShader("SDFOne.glsl");  
  shader = loadShader("SDF.glsl");
  shaderOne = loadShader("RayMarching.glsl");

}

void draw() {
  shader.set("iChannel0", noise);
  shader.set("iResolution", float(width), float(height));
  shader.set("iMouse", float(mouseX), float(mouseY));
  shader.set("iTime", millis() / 1000.0);
  shaderOne.set("iResolution", float(width), float(height));
  shaderOne.set("iMouse", float(mouseX), float(mouseY));
  shaderOne.set("iTime", millis() / 1000.0);
  shaderOne.set("iCam", cam);
  
  shader(shader);

  if( fillVal == true )
  {
  
    resetShader();
    shader(shaderOne);
    
  }
  
  rect(0, 0, width, height);
  
  //println( frameRate );
}
