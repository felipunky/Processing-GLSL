#ifdef GL_ES
precision mediump float;
#endif

#define PROCESSING_COLOR_SHADER

uniform vec2 iResolution;
uniform vec2 iMouse;
uniform float iTime;
uniform sampler2D iChannel0;

#define STEPS      256
#define FAR       50.0
#define EPS      0.002
#define REFLECTIONS  8
#define PI acos( -1.0 )
#define TPI   PI * 2.0
#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)
// Uncomment for funky ass sphere
//#define FUNKY
// Comment for different scene
#define SCENE
// Comment for only XZ repetition
#define REP

// Hash by Dave Hoskins
vec3 hash(vec3 p3)
{
    p3 = fract(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
    
}

float hash13(vec3 p3)
{
    p3  = fract(p3 * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float hash( float a )
{
    
    return fract( sin( a * 45932.92 ) * 234823.9 );
    
}

// Repeat around the origin by a fixed angle.
// For easier use, num of repetitions is use to specify the angle.
float pModPolar(inout vec2 p, float repetitions) {
    float angle = TPI/repetitions;
    float a = atan(p.y, p.x) + angle/2.;
    float r = length(p);
    float c = floor(a/angle);
    a = mod(a,angle) - angle/2.;
    p = vec2(cos(a), sin(a))*r;
    // For an odd number of repetitions, fix cell index of the cell in -x direction
    // (cell index would be e.g. -5 and 5 in the two halves of the cell):
    if (abs(c) >= (repetitions/2.0)) c = abs(c);
    return c;
}

mat2 rot( float a )
{
    
    return mat2( cos( a ), -sin( a ),
                sin( a ),  cos( a )
                );
    
}

vec3 twiY( vec3 p, float f )
{
    
    vec2 mou = iMouse.xy / iResolution.xy;
    
    if( mou.y == 0.0 ) mou.y = 0.4;
    
    float a = mou.y * p.y * f;
    
    p.xz = cos( a ) * p.xz + sin( a ) * vec2( -p.z, p.x );
    
    return p;
    
}

vec3 twiX( vec3 p, float f )
{
    
    vec2 mou = iMouse.xy / iResolution.xy;
    
    if( mou.x == 0.0 ) mou.x = 0.5;
    
    float a = mou.x * p.x * f;
    
    p.yz = cos( a ) * p.yz + sin( a ) * vec2( -p.z, p.y );
    
    return p;
    
}

float sph( vec3 p )
{
    
    return length( p ) - 1.3;
    
}

float sdBox( vec3 p, vec3 b )
{
    
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
    
}

float sph( vec3 p, float r )
{
    
    return length( p ) - r;
    
}

float pla( vec3 p, float d )
{
    
    return p.y + d;
    
}

vec3 modd( vec3 p, float siz )
{
    
    float hal = siz * 0.5;
    
    if( iMouse.z < 0.0 || iMouse.x == 0.0  )
    {
        
        p = mod( p, siz ) - hal;
        
    }
    
    else
    {
        
        p = mod( p + hal, siz ) - hal;
        
    }
    
    return p;
    
}

vec2 map( vec3 p, out vec3 id )
{
    
#ifdef SCENE
    
    float rO = 1.0 + 0.15 * cos( 10.0 * p.x + iTime ) * cos( 10.0 * p.y + iTime ) * cos( 10.0 * p.z + iTime );
    
    float tileSize = 3.5;
    
    id = vec3( int( p.x / tileSize ), int( p.y / tileSize ), int( p.z / tileSize ) );
    
    vec3 pO = p;
    
#ifdef REP
    
    pO = modd( p, tileSize );
    
#else
    
    pO.xz = mod( pO.xz, tileSize ) - tileSize * 0.5;
    
#endif
    
#ifdef FUNKY
    
    vec2 sdSph = vec2( sph( pO, rO ), 0.0 );
    
#else
    
    vec2 sdSph = vec2( sph( pO, 1.0 ), 0.0 );
    
#endif
    
    vec2 sdPla = vec2( pla( p, 0.9 ), 1.0 );
    
    if( sdSph.x < sdPla.x ) sdPla = sdSph;
    
#ifdef REP
    
    return sdSph;
    
#else
    
    return sdPla;
    
#endif
    
#else
    
    vec2 pla = vec2( pla( p, 2.0 ), 1.0 );
    vec2 cubO = vec2( sdBox( p - vec3( 0.0, 0.0, -1.5 ), vec3( 3.0, 3.2, 0.2 ) ), 0.0 );
    vec2 cubT = vec2( sdBox( p - vec3( 3.0, 0.0, 0.0 ), vec3( 0.2, 3.2, 3.2 ) ), 0.0 );
    vec2 cubTh = vec2( sdBox( p - vec3( -3.0, 0.0, 0.0 ), vec3( 0.2, 3.2, 3.2 ) ), 0.0 );
    p = twiX( p, 2.0 );
    p = twiY( p, 2.0 );
    vec2 cub = vec2( sdBox( p, vec3( 1.0 ) ), 0.0 );
    vec2 sds = vec2( sph( p ), 0.0 );
    vec2 fin = max( -sds, cub );
    
    if( pla.x < fin.x ) fin = pla;
    if( fin.x < cubO.x ) cubO = fin;
    if( cubO.x < cubT.x ) cubT = cubO;
    if( cubT.x < cubTh.x ) cubTh = cubT;
    
    vec2 one =  min( cubO, fin );
    vec2 two = min( one, cubT );
    
    return cubTh;
    
#endif
    
}

vec3 norm( vec3 p )
{
    
    vec2 e = vec2( EPS, 0.0 ); vec3 id = vec3( 0 );
    return normalize(  vec3( map( p + e.xyy, id ).x - map( p - e.xyy, id ).x,
                            map( p + e.yxy, id ).x - map( p - e.yxy, id ).x,
                            map( p + e.yyx, id ).x - map( p - e.yyx, id ).x
                            )
                     );
    
}

float ray( vec3 ro, vec3 rd, out float d )
{
    
    float t = 0.0; vec3 id = vec3( 0 );
    for( int i = 0; i < STEPS; ++i )
    {
        
#ifdef SCENE
        
        d = map( ro + rd * t, id ).x;
        
#else
        
        d = 0.5 * map( ro + rd * t, id ).x;
        
#endif
        
        if( d < EPS || t > FAR ) break;
        t += d;
        
    }
    
    return t;
    
}

vec3 sha( vec3 ro, vec3 rd )
{
    
    float d = 0.0;
    float t = ray( ro, rd, d );
    vec3 p = ro + rd * t;
    vec3 n = norm( p );
    vec3 lig = vec3( 0 );
    vec3 id = vec3( 0 );
    vec2 ma = map( p, id );
    
#ifdef SCENE
    
    if( iMouse.z > 0.0 )
    {
        
        lig = normalize( vec3( 1.0, 0.8, 0.6 ) );
        
    }
    
    else
    {
        
        lig = normalize( vec3( 0.0, iTime, cos( iTime * 0.2 ) ) );
        lig.zy *= rot( iTime * 0.1 );
        lig.xz *= rot( iTime * 0.1 );
        
    }
    
#else
    
    lig = normalize( vec3( 1.0, 0.8, 0.6 ) );
    
#endif
    
    vec3 ref = reflect( rd, n );
    
    float dif = max( 0.0, dot( n, lig ) );
    float amb = 0.5 + 0.5 * n.y;
    float spe = pow( clamp( dot( lig, ref ), 0.0, 1.0 ), 32.0 );
    float rim = pow(1.0+dot(n,rd),3.0);
    
    vec3 col = vec3( 0.0 );
    
    col += 0.5 * amb + 0.4 * dif + 1.0 * spe + 0.1 * rim;
    
#ifdef SCENE
    
    //col += 0.5 * hash( id.x + id.y + id.z );
    
    col -= 0.5 * hash( id );
    
#else
    
    if( map( p, id ).y == o.0 ) col *= n;
    
#endif
    
#ifdef REP
    
#else
    
    if( map( p, id ).y == 1.0 ) col = vec3( 0.5 );
    
#endif
    
    return col;
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    vec2 uv = ( -iResolution.xy + 2.0 * fragCoord.xy ) / iResolution.y;
    
    vec2 mou = iMouse.xy / iResolution.xy;
    
    vec3 ro = vec3( 0.0 );
    
    vec3 rd = normalize( vec3( uv, -1.0 ) );
    
#ifdef SCENE
    
    if( iMouse.z > 0.0 )
    {
        
        ro = vec3( 0.0, 0.0, 1.4 );
        ro.zy *= rot( mou.y * TPI );
        rd.zy *= rot( mou.y * TPI );
        ro.xz *= rot( mou.x * TPI );
        rd.xz *= rot( mou.x * TPI );
        
    }
    
    else
    {
        
        ro = vec3( 0.0, iTime, cos( iTime * 0.2 ) );
        ro.zy *= rot( iTime * 0.01 );
        rd.zy *= rot( iTime * 0.02 );
        ro.xz *= rot( iTime * 0.01 );
        rd.xz *= rot( iTime * 0.05 );
        
    }
    
#else
    
    ro = vec3( sin( iTime ), 0.0, 3.0 );
    
#endif
    
    float d = 0.0, t = ray( ro, rd, d );
    
    vec3 p = ro + rd * t;
    
    vec3 n = norm( p );
    
    // Time varying pixel color
    vec3 col = d < EPS ? sha( ro, rd ) : vec3( 0.0 ); vec3 id = vec3( 0 );
    
#ifdef REP
    
    if( map( p, id ).y == 0.0 )
        
        for( int i = 0; i < REFLECTIONS; i++ )
        {
            
            p = p + ro * 0.05;
            p += EPS * rd;
            ro = p + rd * 0.02;
            rd = reflect( rd, n );
            
            col += d < EPS ? sha( ro, rd ) * 0.1 : vec3( 0.0 );
            
        }
    
#else
    
    // ro = vec3( 0, 2, 2 );
    
    for( int i = 0; i < REFLECTIONS; i++ )
    {
        
        p = p + ro * 0.05;
        p += EPS * rd;
        ro = p + rd * 0.02;
        rd = reflect( rd, n );
        
        col += d < EPS ? sha( ro, rd ) * 0.1 : vec3( 0.0 );
        
    }
    
#endif
    
    // Output to screen
    fragColor = vec4(col,1.0);
}
