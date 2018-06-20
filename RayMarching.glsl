#ifdef GL_ES
precision mediump float;
#endif

#define PROCESSING_COLOR_SHADER

uniform vec2 iResolution;
uniform vec2 iMouse;
uniform float iTime;

#define EPS      0.0001
#define STEPS       100
#define FAR       10.0
#define PI acos( -1.0 )
#define TPI    PI * 2.0
// Folding and depth of recursive primitive
#define FRACTALITERATIONS 6
// Uncomment to get real reflections
//#define REFLECTIONS
// Comment to change camera
//#define CAMERA
// Comment to change colours
#define COLOR

vec3 pMod( vec3 p, float d )
{
    
    float hal = d * 0.5;
    return mod( p + hal, d ) - hal;
    
}

mat2 rot( float a )
{
    
    return mat2( cos( a ), -sin( a ),
                sin( a ),  cos( a )
                );
    
}

float sdBox( vec3 p, vec3 b )
{
    
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
    
}

float sph( vec3 p, float f )
{
    
    float sph = length( p ) - f;
    return sph;
    
}


vec2 map( vec3 p, out vec3 tra )
{
    
    vec2 pla = vec2( p.y + 1.0, 0.0 );
    
    //p.xz = mod( p.xz, 5.0 ) - 2.5;
    
    float d = sph(p, 1.0);
    
    p.xz *= rot( iTime * 0.1 );
    
    float s = 1.0;
    for( int m = 0; m < FRACTALITERATIONS; ++m )
    {
        p = abs( p - vec3( 0.1, 0, 0 ) );
        p.xy = p.yx;
        p.xy *= rot( iTime * 0.009 );
        p.xz *= rot( iTime * 0.009 );
        p.yz *= rot( iTime * 0.009 );
        vec3 a = mod( p*s, 2.0 )-1.0;
        s *= 3.0;
        vec3 r = 1.0 - 2.0*abs(a);
        
        float c = sph(r, 1.0)/s;
        d = max(d, -c);
        
        if( c > d ) tra = vec3( 0.0, d * float( m ) * 1000.0 * sin( iTime * 0.8 ),1.0 );
        
    }
    
    vec2 fin = vec2( d, 1.0 );
    //vec2 fin = vec2( length( p ) - 1.0, 1.0 );
    
    if( fin.x < pla.x ) pla = fin;
    return pla;
    
}

vec3 norm( vec3 p )
{
    
    vec2 e = vec2( EPS, 0.0 );
    vec3 tra = vec3( 0 );
    return normalize( vec3( map( p + e.xyy, tra ).x - map( p - e.xyy, tra ).x,
                           map( p + e.yxy, tra ).x - map( p - e.yxy, tra ).x,
                           map( p + e.yyx, tra ).x - map( p - e.yyx, tra ).x
                           )
                     );
    
}

float softShadows( vec3 ro, vec3 rd )
{
    
    float res = 1.0; vec3 tra = vec3( 0 );
    for( float t = 0.1; t < 8.0; ++t )
    {
        float h = map( ro + rd * t, tra ).x;
        if( h < EPS ) return 0.0;
        res = min( res, 8.0 * h / t );
        
    }
    
    return res;
}

float ray( vec3 ro, vec3 rd, out float d )
{
    
    vec3 col = vec3( 0.0 );
    float t = 0.0; vec3 tra = vec3( 0 );
    for( int i = 0; i < STEPS; ++i )
    {
        
        d = 0.5 * map( ro + rd * t, tra ).x;
        if( d < EPS || t > FAR ) break;
        t += d;
        
    }
    
    return t;
    
}

vec3 shad( vec3 ro, vec3 rd )
{
    
    float d = 0.0, t = ray( ro, rd, d );
    vec3 p = ro + rd * t;
    vec3 n = normalize( norm( p ) );
    vec3 col = vec3( 0 );
    vec3 tra = vec3( 0);
    float ma = map( p, tra ).x;
    vec3 lig = normalize( vec3( 1.0, 0.8, 0.6 ) );
    vec3 blig = normalize( -lig );
    vec3 ref = reflect( rd, n );
    
    float sha = softShadows( p, lig );
    float con =  1.0 ;
    float amb = 0.5 + 0.5 * n.y;
    float dif = max( 0.0, dot( n, lig ) );
    float bac = 0.5 + 0.2 * max( 0.0, dot( n, blig ) );
    float spe = pow( clamp( dot( ref, lig ), 0.0, 1.0 ), 16.0 );
    
    col = amb * vec3( 0.2 );
    col += 0.4 * bac;
    col += dif * vec3( 1.0 ) * sha;
    
    if( map( p, tra ).y == 0.0 )
    {
        
        col *= 1.5;
        
    }
    
    else
    {
        
        col += 1.0 * spe;
        col += 0.3 * tra;
        col += 0.2 * vec3( 0.1, 0.2, 0.3 );
#ifdef REFLECTIONS
#else
#endif
#ifdef COLOR
        col -= 1.0 * vec3( 0.5 );
#else
#endif
    }
    
    return col;
    
}


void main( )
{
    // Normalized pixel coordinates (from -1 to 1)
    vec2 uv = ( -iResolution.xy + 2.0 * gl_FragCoord.xy ) / iResolution.y;
    
    vec2 mou = iMouse.xy / iResolution.xy;
    
#ifdef CAMERA
    vec3 ro = 0.2 * vec3( sin( iTime * 0.1 ), 0.0, cos( iTime * 0.1 ) );
#else
    vec3 ro = vec3( 0.0, 0.2 * cos( iTime * 0.1  ), 1.0 + sin( iTime * 0.1 ) );
#endif
    vec3 ww = normalize( vec3( 0.0, 0.0, 0.0 ) - ro );
    vec3 uu = normalize( cross( vec3( 0.0, 1.0, 0.0 ), ww ) );
    vec3 vv = normalize( cross( ww, uu ) );
    vec3 rd = normalize( uv.x * uu + uv.y * vv + 1.5 * ww  );
    //vec3 rd = normalize( vec3( uv, -1.0 ) );
    
    float d = 0.0;
    float t = ray( ro, rd, d );
    vec3 p = ro + rd * t;
    vec3 n = norm( p ); vec3 tra = vec3( 0 );
    
    vec3 col = d < EPS ? shad( ro, rd ) : vec3( mix( vec3(1), vec3(0.2, 0.1, 0.3), uv.y ) );
    
#ifdef REFLECTIONS
    if( map( p, tra ).y == 1.0 )
        
        rd = normalize( reflect( rd, n ) );
    ro = p + rd * EPS;
    
    if( d < EPS ) col = shad( ro, rd );
#else
#endif
    
    // Output to screen
    gl_FragColor = vec4(col,1.0);
    
}
