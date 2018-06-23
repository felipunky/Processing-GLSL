#ifdef GL_ES
precision mediump float;
#endif

#define PROCESSING_COLOR_SHADER

uniform vec2 iResolution;
uniform vec2 iMouse;
uniform float iTime;
uniform sampler2D iChannel0;

#define STEPS       128
#define FAR         10.
#define PI acos( -1.0 )
#define HASHSCALE .1031

// https://www.shadertoy.com/view/4djSRW

float hash(float p)
{
    vec3 p3  = fract(vec3(p) * HASHSCALE);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// iq's

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = textureLod( iChannel0, (uv+ 0.5)/256.0, 0.0 ).yx;
    return mix( rg.x, rg.y, f.z );
}

float fbm( in vec3 p )
{
    
    //float wav = texture( iChannel1, vec2( 0.0, 0.25 ) ).x;
    //float fre = texture( iChannel1, vec2( 0.0, 0.15 ) ).x;
    float f = 0.0;
    f += 0.5000 * noise( p ); p *= 2.02; p -= iTime * 0.1;// + wav;
    f += 0.2500 * noise( p ); p *= 2.03; p += iTime * 0.2;// + fre;
    f += 0.1250 * noise( p ); p *= 2.01; p -= iTime * 0.1;// + wav;
    f += 0.0625 * noise( p );
    f += 0.0125 * noise( p );
    return f / 0.9375;
    
}

float map( vec3 p )
{
    
    //return p.y + 1.0 * fbm( p + iTime * 0.2 );
    //return 0.4 - length( p ) * fbm( p + iTime );
    
    p.z -= iTime * 0.4;
    
    float f = fbm( p );
    
    return f;
    
}

float ray( vec3 ro, vec3 rd, out float den )
{
    
    float t = 0.0, maxD = 0.0, d = 1.0; den = 0.0;
    
    for( int i = 0; i < STEPS; ++i )
    {
        
        vec3 p = ro + rd * t;
        
        den = d * ( 1.0 * map( p ) * t * t * 0.025 );
        //den = map( p );
        maxD = maxD < den ? den : maxD;
        
        if( maxD > 1.0 || t > FAR ) break;
        
        // https://www.shadertoy.com/view/MscXRH
        //t += max( maxD*.1, .05 );
        
        t += 0.05;
        
    }
    
    den = maxD;
    
    return t;
    
}

vec3 shad( vec3 ro, vec3 rd, vec2 uv )
{
    
    float den = 0.0;
    float t = ray( ro, rd, den );
    
    vec3 p = ro + rd * t;
    
    vec3 col = mix( mix( vec3( 0.7 ), vec3( 0.2, 0.5, 0.8 ), uv.y ), mix( vec3( 0 ), vec3( 1 ), den ), den );
    //vec3 col = mix( vec3( 1 ), colB, den );
    
    col *= sqrt( col );
    
    return col;
    
}

void main( )
{
    
    vec2 uv = ( -iResolution.xy + 2.0 * gl_FragCoord.xy ) / iResolution.y;
    
    vec2 mou = iMouse.xy / iResolution.xy;
    
    vec3 ro = 3.0 * vec3( sin( mou.x * 2.0 * PI ), 0.0, cos( -mou.x * 2.0 * PI ) );
    vec3 ww = normalize( vec3( 0 ) - ro );
    vec3 uu = normalize( cross( vec3( 0, 1, 0 ), ww ) );
    vec3 vv = normalize( cross( ww, uu ) );
    vec3 rd = normalize( uv.x * uu + uv.y * vv + 1.5 * ww );
    
    float den = 0.0, t = ray( ro, rd, den );
    
    vec3 col = shad( ro, rd, uv );
    
    // Output to screen
    gl_FragColor = vec4(col,1.0);
}
