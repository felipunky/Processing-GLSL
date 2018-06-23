#ifdef GL_ES
precision mediump float;
#endif

#define TEXTURE

uniform vec2 iResolution;
uniform vec2 iMouse;
uniform float iTime;
uniform samplerCube iChannel0;

#define EPS 0.0002
#define STEPS 1028
#define FAR 20.0

const float PI = acos( -1.0 );

vec3 pMod3( inout vec3 p, float s )
{
    
    vec3 a = mod( p*s, 2.0 )-1.0;
    return a;
    
}

// Sign function that doesn't return 0
float sgn(float x) {
    return (x<0.)?-1.:1.;
}

vec2 sgn(vec2 v) {
    return vec2((v.x<0.)?-1.:1., (v.y<0.)?-1.:1.);
}

// Mirror at an axis-aligned plane which is at a specified distance <dist> from the origin.
float pMirror (inout float p, float dist) {
    float s = sgn(p);
    p = abs(p)-dist;
    return s;
}

// Mirror in both dimensions and at the diagonal, yielding one eighth of the space.
// translate by dist before mirroring.
vec2 pMirrorOctant (inout vec2 p, vec2 dist) {
    vec2 s = sgn(p);
    pMirror(p.x, dist.x);
    pMirror(p.y, dist.y);
    if (p.y > p.x)
        p.xy = p.yx;
    return s;
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

float map ( vec3 p, out vec3 tra )
{
    
    pMirrorOctant( p.xz, vec2( iTime * 0.8, 1.0 ) );
    pMirrorOctant( p.xy, vec2( 0.2, iTime * 0.8 ) );
    p = pMod3( p, ( 0.3 ) );
    float box = sdBox( p, vec3( 1.0 ) );
    float tim = sin( ( iTime ) + sin( iTime ) * 0.5 );
    float sp = sph( p, 1.2 );
    float s = 1.0;
    float obj = max( -sp, box );
    
    float d = sdBox(p,vec3(1.0));
    for( int m=0; m<5; m++ )
    {
        vec3 a = mod( p*s, 2.0 )-1.0;
        s *= 4.0;
        vec3 r = 1.0 - 3.0*abs(a);
        float c = sph( r, 1.2 )/s;
        d = max(d,-c);
        if( c < d )
        {
            
            tra = vec3( d * float( m ) * 3000.0 * sin( iTime * 0.8 ), float( m ), 1.0 );
            
        }
    }
    
    return max( obj, d );
    
}

vec3 norm( vec3 p )
{
    
    vec3 tra = vec3( 0.0 );
    vec2 e = vec2( EPS, 0.0 );
    return normalize( vec3( map( p + e.xyy, tra ) - map( p - e.xyy, tra ),
                           map( p + e.yxy, tra ) - map( p - e.yxy, tra ),
                           map( p + e.yyx, tra ) - map( p - e.yyx, tra )
                           )
                     );
    
}

float softShadows( in vec3 ro, in vec3 rd )
{
    
    vec3 tra = vec3( 0.0 );
    float res = 1.0;
    for( float t = 0.1; t < 8.0; ++t )
    {
        
        float h = map( ro + rd * t, tra );
        res = min( res, 8.0 * h / t );
        
    }
    
    return res;
    
}

vec3 shad( vec3 ro, vec3 rd, float t )
{
    
    vec3 p = ro + rd * t;
    vec3 n = norm( p );
    vec3 lig = normalize( vec3( 1.0, 0.8, 0.6 ) );
    vec3 blig = vec3( -lig.x, -lig.y, -lig.z );
    vec3 col = vec3( 0.0 );
    vec3 tra = vec3( 1.0 );
    vec3 ref = reflect( rd, n );
    
    float ma = map( p, tra );
    float amb = 0.5 + 0.5 * n.y;
    float dif = max( 0.0, dot( lig, n ) );
    float bac = max( 0.0,  0.5 * dot( blig, n ) );
    float sha = softShadows( p, lig );
    float spe = pow( clamp( dot( lig, ref ), 0.0, 1.0 ), 16.0 );
    float speO = pow( clamp( dot( blig, ref ), 0.0, 1.0 ), 16.0 );
    
    col += 0.2 * amb;
    col += dif;
    col += bac;
    col += sha * spe * speO;
    col += mix( vec3( 0.0 ), vec3( 0.0, 0.4, 0.0 ), tra.x );
    col += mix( vec3( 1.0 ), vec3( 0.0 ), tra.y );
    if( col.x > 0.0 ) col *= vec3( 0.8, 0.1, 0.2 );
    col += texture( iChannel0, normalize( reflect( rd, n ) ) ).rgb * 0.5;
    col *= vec3( 1.5 );
    col *= sqrt( col );
    return col;
    
}

vec3 ray( vec3 ro, vec3 rd )
{
    
    vec3 col = vec3( 0.0 );
    vec3 tra = vec3( 0.0 );
    
    float t = 0.0, d = EPS;
    for( int i = 0; i < STEPS; ++i )
    {
        
        d = 0.5 * map( ro + rd * t, tra );
        if( d < EPS || t > FAR ) break;
        t += d;
        
    }
    
    return col = d < EPS ? shad( ro, rd, t ) : vec3( 0.0 );
    
}

void main( )
{
    
    vec2 uv = ( -iResolution.xy + 2.0 * gl_FragCoord.xy ) / iResolution.y;
    
    //vec2 uv = fragCoord.xy / iResolution.y;
    
    float tim = iTime * 0.1;
    
    vec2 mou = iMouse.xy / iResolution.y;
    
    vec3 ro = vec3( 0.0 );
    
    //vec3 ro = 3.5 * vec3( 1.2 - sin( tim ), sin( tim ), cos( tim ) );
    if( mou.x == 0.0 )
        ro = 5.0 * vec3( sin( 5.0 + mou.x * PI ), sin( -10.0 + mou.y * PI * 2.0 ), cos( 6.0 -mou.x * PI ) );
    else if( mou.x != 0.0 )
        ro = 5.0 * vec3( sin( mou.x * PI ), mou.y, cos( -mou.x * PI ) );
    vec3 ww = normalize( vec3( 0.0 ) - ro );
    vec3 uu = normalize( cross( vec3( 0.0, 1.0, 0.0 ), ww ) );
    vec3 vv = normalize( cross( ww, uu ) );
    vec3 rd = normalize( uv.x * uu + uv.y * vv + 1.5 * ww );
    //vec3 rd = normalize( vec3( uv, -1.0 ) );
    
    vec3 tra = vec3( 0.0 );
    
    vec3 col = ray( ro, rd );
    
    // Output to screen
    gl_FragColor = vec4(col,1.0);
}
