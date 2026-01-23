// Toony Colors Pro+Mobile 2
// (c) 2014-2025 Jean Moreno

// Terrain AddPass shader:
// This shader is used if your terrain uses more than 4 texture layers.
// It will draw the additional texture layers additively, by groups of 4 layers.

Shader "Hidden/Toony Colors Pro 2/User/ToonyTerrain-AddPass"
{
	Properties
	{
		[TCP2HeaderHelp(Base)]
		_BaseColor ("Color", Color) = (1,1,1,1)
		[TCP2ColorNoAlpha] _HColor ("Highlight Color", Color) = (0.75,0.75,0.75,1)
		[TCP2ColorNoAlpha] _SColor ("Shadow Color", Color) = (0.2,0.2,0.2,1)
		[TCP2Separator]

		[TCP2Header(Ramp Shading)]
		
		_RampThreshold ("Threshold", Range(0.01,1)) = 0.5
		_RampSmoothing ("Smoothing", Range(0.001,1)) = 0.5
		[IntRange] _BandsCount ("Bands Count", Range(1,20)) = 4
		_BandsSmoothing ("Bands Smoothing", Range(0.001,1)) = 0.1
		[TCP2Separator]
		[TCP2HeaderHelp(Terrain)]
		_HeightTransition ("Height Smoothing", Range(0, 1.0)) = 0.0
		_Layer0HeightOffset ("Layer 0 Height Offset", Range(-1,1)) = 0
		_Layer1HeightOffset ("Layer 1 Height Offset", Range(-1,1)) = 0
		_Layer2HeightOffset ("Layer 2 Height Offset", Range(-1,1)) = 0
		_Layer3HeightOffset ("Layer 3 Height Offset", Range(-1,1)) = 0
		[HideInInspector] TerrainMeta_maskMapTexture ("Mask Map", 2D) = "white" {}
		[HideInInspector] TerrainMeta_normalMapTexture ("Normal Map", 2D) = "bump" {}
		[HideInInspector] TerrainMeta_normalScale ("Normal Scale", Float) = 1
		[Toggle(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)] _EnableInstancedPerPixelNormal("Enable Instanced per-pixel normal", Float) = 1.0
		[TCP2Separator]
		
		[TCP2HeaderHelp(Sketch)]
		[Toggle(TCP2_SKETCH)] _UseSketch ("Enable Sketch Effect", Float) = 0
		_ProgressiveSketchTexture ("Progressive Texture", 2D) = "black" {}
		_ProgressiveSketchSmoothness ("Progressive Smoothness", Range(0.005,0.5)) = 0.1
		[TCP2Separator]
		
		[TCP2HeaderHelp(Outline)]
		_OutlineWidth ("Width", Range(0.1,4)) = 1
		_OutlineColorVertex ("Color", Color) = (0,0,0,1)
		// Outline Normals
		[TCP2MaterialKeywordEnumNoPrefix(Regular, _, Vertex Colors, TCP2_COLORS_AS_NORMALS, Tangents, TCP2_TANGENT_AS_NORMALS, UV1, TCP2_UV1_AS_NORMALS, UV2, TCP2_UV2_AS_NORMALS, UV3, TCP2_UV3_AS_NORMALS, UV4, TCP2_UV4_AS_NORMALS)]
		_NormalsSource ("Outline Normals Source", Float) = 0
		[TCP2MaterialKeywordEnumNoPrefix(Full XYZ, TCP2_UV_NORMALS_FULL, Compressed XY, _, Compressed ZW, TCP2_UV_NORMALS_ZW)]
		_NormalsUVType ("UV Data Type", Float) = 0
		[TCP2Separator]
		[TCP2Vector4Floats(Contrast X,Contrast Y,Contrast Z,Smoothing,1,16,1,16,1,16,0.05,10)] _TriplanarSamplingStrength ("Triplanar Sampling Parameters", Vector) = (8,8,8,0.5)
		
		[HideInInspector] [NoScaleOffset] _Normal0 ("Layer 0 Normal Map AddPass", 2D) = "bump" {}
		[HideInInspector] [NoScaleOffset] _Normal1 ("Layer 1 Normal Map AddPass", 2D) = "bump" {}
		[HideInInspector] [NoScaleOffset] _Normal2 ("Layer 2 Normal Map AddPass", 2D) = "bump" {}
		[HideInInspector] [NoScaleOffset] _Normal3 ("Layer 3 Normal Map AddPass", 2D) = "bump" {}
		[HideInInspector] _Splat0 ("Layer 0 Albedo AddPass", 2D) = "gray" {}
		[HideInInspector] _Splat1 ("Layer 1 Albedo AddPass", 2D) = "gray" {}
		[HideInInspector] _Splat2 ("Layer 2 Albedo AddPass", 2D) = "gray" {}
		[HideInInspector] _Splat3 ("Layer 3 Albedo AddPass", 2D) = "gray" {}
		[HideInInspector] [NoScaleOffset] _Mask0 ("Layer 0 Mask", 2D) = "gray" {}
		[HideInInspector] [NoScaleOffset] _Mask1 ("Layer 1 Mask", 2D) = "gray" {}
		[HideInInspector] [NoScaleOffset] _Mask2 ("Layer 2 Mask", 2D) = "gray" {}
		[HideInInspector] [NoScaleOffset] _Mask3 ("Layer 3 Mask", 2D) = "gray" {}

		[ToggleOff(_RECEIVE_SHADOWS_OFF)] _ReceiveShadowsOff ("Receive Shadows", Float) = 1

		// Avoid compile error if the properties are ending with a drawer
		[HideInInspector] __dummy__ ("unused", Float) = 0
	}

	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalPipeline"
			"RenderType" = "Opaque"
			"Queue"="Geometry-99"
			"IgnoreProjector"="True"
			"TerrainCompatible"="True"
		}

		HLSLINCLUDE
		#define fixed half
		#define fixed2 half2
		#define fixed3 half3
		#define fixed4 half4

		#if UNITY_VERSION >= 202020
			#define URP_10_OR_NEWER
		#endif
		#if UNITY_VERSION >= 202120
			#define URP_12_OR_NEWER
		#endif
		#if UNITY_VERSION >= 202220
			#define URP_14_OR_NEWER
		#endif

		// Texture/Sampler abstraction
		#define TCP2_TEX2D_WITH_SAMPLER(tex)						TEXTURE2D(tex); SAMPLER(sampler##tex)
		#define TCP2_TEX2D_NO_SAMPLER(tex)							TEXTURE2D(tex)
		#define TCP2_TEX2D_SAMPLE(tex, samplertex, coord)			SAMPLE_TEXTURE2D(tex, sampler##samplertex, coord)
		#define TCP2_TEX2D_SAMPLE_LOD(tex, samplertex, coord, lod)	SAMPLE_TEXTURE2D_LOD(tex, sampler##samplertex, coord, lod)

		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

		// Terrain
		#define TERRAIN_INSTANCED_PERPIXEL_NORMAL
		#define TERRAIN_SPLAT_ADDPASS
		
		//================================================================
		// Terrain Shader specific
		
		//----------------------------------------------------------------
		// Per-layer variables
		
		CBUFFER_START(_Terrain)
			float4 _Control_ST;
			float4 _Control_TexelSize;
			half _HeightTransition;
			half _DiffuseHasAlpha0, _DiffuseHasAlpha1, _DiffuseHasAlpha2, _DiffuseHasAlpha3;
			half _LayerHasMask0, _LayerHasMask1, _LayerHasMask2, _LayerHasMask3;
			// half4 _Splat0_ST, _Splat1_ST, _Splat2_ST, _Splat3_ST;
			half _NormalScale0, _NormalScale1, _NormalScale2, _NormalScale3;
		
			#ifdef UNITY_INSTANCING_ENABLED
				float4 _TerrainHeightmapRecipSize;   // float4(1.0f/width, 1.0f/height, 1.0f/(width-1), 1.0f/(height-1))
				float4 _TerrainHeightmapScale;       // float4(hmScale.x, hmScale.y / (float)(kMaxHeight), hmScale.z, 0.0f)
			#endif
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif
		CBUFFER_END
		
		//----------------------------------------------------------------
		// Terrain textures
		
		TCP2_TEX2D_WITH_SAMPLER(_Control);
		
		#if defined(TERRAIN_BASE_PASS)
			TCP2_TEX2D_WITH_SAMPLER(_MainTex);
			TCP2_TEX2D_WITH_SAMPLER(_NormalMap);
		#endif
		
		//----------------------------------------------------------------
		// Terrain Instancing
		
		#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
			#define ENABLE_TERRAIN_PERPIXEL_NORMAL
		#endif
		
		#ifdef UNITY_INSTANCING_ENABLED
			TCP2_TEX2D_NO_SAMPLER(_TerrainHeightmapTexture);
			TCP2_TEX2D_WITH_SAMPLER(_TerrainNormalmapTexture);
		#endif
		
		UNITY_INSTANCING_BUFFER_START(Terrain)
			UNITY_DEFINE_INSTANCED_PROP(float4, _TerrainPatchInstanceData)  // float4(xBase, yBase, skipScale, ~)
		UNITY_INSTANCING_BUFFER_END(Terrain)
		
		void TerrainInstancing(inout float4 positionOS, inout float3 normal, inout float2 uv)
		{
		#ifdef UNITY_INSTANCING_ENABLED
			float2 patchVertex = positionOS.xy;
			float4 instanceData = UNITY_ACCESS_INSTANCED_PROP(Terrain, _TerrainPatchInstanceData);
		
			float2 sampleCoords = (patchVertex.xy + instanceData.xy) * instanceData.z; // (xy + float2(xBase,yBase)) * skipScale
			float height = UnpackHeightmap(_TerrainHeightmapTexture.Load(int3(sampleCoords, 0)));
		
			positionOS.xz = sampleCoords * _TerrainHeightmapScale.xz;
			positionOS.y = height * _TerrainHeightmapScale.y;
		
			#ifdef ENABLE_TERRAIN_PERPIXEL_NORMAL
				normal = float3(0, 1, 0);
			#else
				normal = _TerrainNormalmapTexture.Load(int3(sampleCoords, 0)).rgb * 2 - 1;
			#endif
			uv = sampleCoords * _TerrainHeightmapRecipSize.zw;
		#endif
		}
		
		void TerrainInstancing(inout float4 positionOS, inout float3 normal)
		{
			float2 uv = { 0, 0 };
			TerrainInstancing(positionOS, normal, uv);
		}
		
		//----------------------------------------------------------------
		// Terrain Holes
		
		#if defined(_ALPHATEST_ON)
			TCP2_TEX2D_WITH_SAMPLER(_TerrainHolesTexture);
		
			void ClipHoles(float2 uv)
			{
				float hole = TCP2_TEX2D_SAMPLE(_TerrainHolesTexture, _TerrainHolesTexture, uv).r;
				clip(hole == 0.0f ? -1 : 1);
			}
		#endif
		
		//----------------------------------------------------------------
		// Height-based blending
		
		void HeightBasedSplatModify(inout half4 splatControl, in half4 splatHeight)
		{
			// We multiply by the splat Control weights to get combined height
			splatHeight *= splatControl.rgba;
			half maxHeight = max(splatHeight.r, max(splatHeight.g, max(splatHeight.b, splatHeight.a)));
		
			// Ensure that the transition height is not zero.
			half transition = max(_HeightTransition, 1e-5);
		
			// This sets the highest splat to "transition", and everything else to a lower value relative to that
			// Then we clamp this to zero and normalize everything
			half4 weightedHeights = splatHeight + transition - maxHeight.xxxx;
			weightedHeights = max(0, weightedHeights);
		
			// We need to add an epsilon here for active layers (hence the blendMask again)
			// so that at least a layer shows up if everything's too low.
			weightedHeights = (weightedHeights + 1e-6) * splatControl;
		
			// Normalize (and clamp to epsilon to keep from dividing by zero)
			half sumHeight = max(dot(weightedHeights, half4(1, 1, 1, 1)), 1e-6);
			splatControl = weightedHeights / sumHeight.xxxx;
		}
		
		// Uniforms

		// Shader Properties
		TCP2_TEX2D_WITH_SAMPLER(_Normal0);
		TCP2_TEX2D_NO_SAMPLER(_Normal1);
		TCP2_TEX2D_NO_SAMPLER(_Normal2);
		TCP2_TEX2D_NO_SAMPLER(_Normal3);
		TCP2_TEX2D_WITH_SAMPLER(_Splat0);
		TCP2_TEX2D_NO_SAMPLER(_Splat1);
		TCP2_TEX2D_NO_SAMPLER(_Splat2);
		TCP2_TEX2D_NO_SAMPLER(_Splat3);
		TCP2_TEX2D_WITH_SAMPLER(_ProgressiveSketchTexture);
		TCP2_TEX2D_WITH_SAMPLER(_Mask0);
		TCP2_TEX2D_NO_SAMPLER(_Mask1);
		TCP2_TEX2D_NO_SAMPLER(_Mask2);
		TCP2_TEX2D_NO_SAMPLER(_Mask3);

		CBUFFER_START(UnityPerMaterial)
			
			// Shader Properties
			float _OutlineWidth;
			fixed4 _OutlineColorVertex;
			float _Layer0HeightOffset;
			float _Layer1HeightOffset;
			float _Layer2HeightOffset;
			float _Layer3HeightOffset;
			float4 _Splat0_ST;
			float4 _Splat1_ST;
			float4 _Splat2_ST;
			float4 _Splat3_ST;
			fixed4 _BaseColor;
			float _RampThreshold;
			float _RampSmoothing;
			float _BandsCount;
			float _BandsSmoothing;
			float4 _ProgressiveSketchTexture_ST;
			float _ProgressiveSketchSmoothness;
			fixed4 _SColor;
			fixed4 _HColor;
			float4 _TriplanarSamplingStrength;
		CBUFFER_END

		// Texture sampling with triplanar UVs
		float4 tex2D_triplanar(sampler2D samp, float4 tiling_offset, float3 worldPos, float3 worldNormal)
		{
			half4 sample_y = ( tex2D(samp, worldPos.xz * tiling_offset.xy + tiling_offset.zw).rgba );
			half4 sample_x = ( tex2D(samp, worldPos.zy * tiling_offset.xy + tiling_offset.zw).rgba );
			half4 sample_z = ( tex2D(samp, worldPos.xy * tiling_offset.xy + tiling_offset.zw).rgba );
			
			// blending
			half3 blendWeights = pow(abs(worldNormal), _TriplanarSamplingStrength.xyz / _TriplanarSamplingStrength.w);
			blendWeights = blendWeights / (blendWeights.x + abs(blendWeights.y) + blendWeights.z);
			half4 triplanar = sample_x * blendWeights.x + sample_y * blendWeights.y + sample_z * blendWeights.z;
			
			return triplanar;
		}
			
		// Version with separate texture and sampler
		#define TCP2_TEX2D_SAMPLE_TRIPLANAR(tex, samplertex, tiling, positionWS, normalWS) tex2D_triplanar(tex, sampler##samplertex, tiling, positionWS, normalWS)
		float4 tex2D_triplanar(Texture2D tex, SamplerState samp, float4 tiling_offset, float3 worldPos, float3 worldNormal)
		{
			half4 sample_y = ( tex.Sample(samp, worldPos.xz * tiling_offset.xy + tiling_offset.zw).rgba );
			half4 sample_x = ( tex.Sample(samp, worldPos.zy * tiling_offset.xy + tiling_offset.zw).rgba );
			half4 sample_z = ( tex.Sample(samp, worldPos.xy * tiling_offset.xy + tiling_offset.zw).rgba );
			
			// blending
			half3 blendWeights = pow(abs(worldNormal), _TriplanarSamplingStrength.xyz / _TriplanarSamplingStrength.w);
			blendWeights = blendWeights / (blendWeights.x + abs(blendWeights.y) + blendWeights.z);
			half4 triplanar = sample_x * blendWeights.x + sample_y * blendWeights.y + sample_z * blendWeights.z;
			
			return triplanar;
		}
		
		// Built-in renderer (CG) to SRP (HLSL) bindings
		#define UnityObjectToClipPos TransformObjectToHClip
		#define _WorldSpaceLightPos0 _MainLightPosition
		
		ENDHLSL

		// Outline Include
		HLSLINCLUDE

		struct appdata_outline
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 texcoord0 : TEXCOORD0;
			#if TCP2_UV2_AS_NORMALS
			float4 texcoord1 : TEXCOORD1;
		#elif TCP2_UV3_AS_NORMALS
			float4 texcoord2 : TEXCOORD2;
		#elif TCP2_UV4_AS_NORMALS
			float4 texcoord3 : TEXCOORD3;
		#endif
		#if TCP2_COLORS_AS_NORMALS
			float4 vertexColor : COLOR;
		#endif
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};

		struct v2f_outline
		{
			float4 vertex : SV_POSITION;
			float4 vcolor : TEXCOORD0;
			float2 pack1 : TEXCOORD1; /* pack1.xy = texcoord0 */
			UNITY_VERTEX_INPUT_INSTANCE_ID
			UNITY_VERTEX_OUTPUT_STEREO
		};

		v2f_outline vertex_outline (appdata_outline v)
		{
			v2f_outline output = (v2f_outline)0;

			UNITY_SETUP_INSTANCE_ID(v);
			UNITY_TRANSFER_INSTANCE_ID(v, output);
			UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

			// Texture Coordinates
			output.pack1.xy = v.texcoord0.xy;
			// Shader Properties Sampling
			float __outlineWidth = ( _OutlineWidth );
			float4 __outlineColorVertex = ( _OutlineColorVertex.rgba );

		#ifdef TCP2_COLORS_AS_NORMALS
			//Vertex Color for Normals
			float3 normal = (v.vertexColor.xyz*2) - 1;
		#elif TCP2_TANGENT_AS_NORMALS
			//Tangent for Normals
			float3 normal = v.tangent.xyz;
		#elif TCP2_UV1_AS_NORMALS || TCP2_UV2_AS_NORMALS || TCP2_UV3_AS_NORMALS || TCP2_UV4_AS_NORMALS
			#if TCP2_UV1_AS_NORMALS
				#define uvChannel texcoord0
			#elif TCP2_UV2_AS_NORMALS
				#define uvChannel texcoord1
			#elif TCP2_UV3_AS_NORMALS
				#define uvChannel texcoord2
			#elif TCP2_UV4_AS_NORMALS
				#define uvChannel texcoord3
			#endif
		
			#if TCP2_UV_NORMALS_FULL
			//UV for Normals, full
			float3 normal = v.uvChannel.xyz;
			#else
			//UV for Normals, compressed
			#if TCP2_UV_NORMALS_ZW
				#define ch1 z
				#define ch2 w
			#else
				#define ch1 x
				#define ch2 y
			#endif
			float3 n;
			//unpack uvs
			v.uvChannel.ch1 = v.uvChannel.ch1 * 255.0/16.0;
			n.x = floor(v.uvChannel.ch1) / 15.0;
			n.y = frac(v.uvChannel.ch1) * 16.0 / 15.0;
			//- get z
			n.z = v.uvChannel.ch2;
			//- transform
			n = n*2 - 1;
			float3 normal = n;
			#endif
		#else
			float3 normal = v.normal;
		#endif
		
		#if TCP2_ZSMOOTH_ON
			//Correct Z artefacts
			normal = UnityObjectToViewPos(normal);
			normal.z = -_ZSmooth;
		#endif
			float size = 1;
		
		#if !defined(SHADOWCASTER_PASS)
			output.vertex = UnityObjectToClipPos(v.vertex.xyz + normal * __outlineWidth * size * 0.01);
		#else
			v.vertex = v.vertex + float4(normal,0) * __outlineWidth * size * 0.01;
		#endif
		
			output.vcolor.xyzw = __outlineColorVertex;

			return output;
		}

		float4 fragment_outline (v2f_outline input) : SV_Target
		{

			UNITY_SETUP_INSTANCE_ID(input);
			UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

			// Shader Properties Sampling
			float4 __outlineColor = ( float4(1,1,1,1) );

			half4 outlineColor = __outlineColor * input.vcolor.xyzw;

			return outlineColor;
		}

		ENDHLSL
		// Outline Include End
		Pass
		{
			Name "Main"
			Tags
			{
				"LightMode"="UniversalForward"
			}
		Blend One One

			HLSLPROGRAM
			// Required to compile gles 2.0 with standard SRP library
			// All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 3.0

			// -------------------------------------
			// Material keywords
			#pragma shader_feature_local _ _RECEIVE_SHADOWS_OFF

			// -------------------------------------
			// Universal Render Pipeline keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH

			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ _CLUSTER_LIGHT_LOOP
			#include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"

			// -------------------------------------

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing
			#pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap forwardadd

			#pragma vertex Vertex
			#pragma fragment Fragment

			//--------------------------------------
			// Toony Colors Pro 2 keywords
			#pragma shader_feature_local _TERRAIN_INSTANCED_PERPIXEL_NORMAL
			#pragma multi_compile_local_fragment __ _ALPHATEST_ON
			#pragma shader_feature_local_fragment TCP2_SKETCH

			// vertex input
			struct Attributes
			{
				float4 vertex       : POSITION;
				float3 normal       : NORMAL;
				float4 texcoord0 : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			// vertex output / fragment input
			struct Varyings
			{
				float4 positionCS     : SV_POSITION;
				float3 normal         : NORMAL;
				float4 worldPosAndFog : TEXCOORD0;
			#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord    : TEXCOORD1; // compute shadow coord per-vertex for the main light
			#endif
			#ifdef _ADDITIONAL_LIGHTS_VERTEX
				half3 vertexLights : TEXCOORD2;
			#endif
				float3 pack0 : TEXCOORD3; /* pack0.xyz = tangent */
				float3 pack1 : TEXCOORD4; /* pack1.xyz = bitangent */
				float2 pack2 : TEXCOORD5; /* pack2.xy = texcoord0 */
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#if USE_FORWARD_PLUS || USE_CLUSTER_LIGHT_LOOP
				// Fake InputData struct needed for Forward+ macro
				struct InputDataForwardPlusDummy
				{
					float3  positionWS;
					float2  normalizedScreenSpaceUV;
				};
			#endif

			Varyings Vertex(Attributes input)
			{
				Varyings output = (Varyings)0;

				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				TerrainInstancing(input.vertex, input.normal, input.texcoord0.xy);

				// Texture Coordinates
				output.pack2.xy = input.texcoord0.xy;

				float3 worldPos = mul(UNITY_MATRIX_M, input.vertex).xyz;
				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.vertex.xyz);
			#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				output.shadowCoord = GetShadowCoord(vertexInput);
			#endif

				float4 vertexTangent = -float4(cross(float3(0, 0, 1), input.normal), 1.0);
				VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normal, vertexTangent);
			#ifdef _ADDITIONAL_LIGHTS_VERTEX
				// Vertex lighting
				output.vertexLights = VertexLighting(vertexInput.positionWS, vertexNormalInput.normalWS);
			#endif

				// world position
				output.worldPosAndFog = float4(vertexInput.positionWS.xyz, 0);

				// normal
				output.normal = normalize(vertexNormalInput.normalWS);

				// tangent
				output.pack0.xyz = vertexNormalInput.tangentWS;
				output.pack1.xyz = vertexNormalInput.bitangentWS;

				// clip position
				output.positionCS = vertexInput.positionCS;

				return output;
			}

			half4 Fragment(Varyings input
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

				float3 positionWS = input.worldPosAndFog.xyz;
				float3 normalWS = normalize(input.normal);
				half3 tangentWS = input.pack0.xyz;
				half3 bitangentWS = input.pack1.xyz;
				half3x3 tangentToWorldMatrix = half3x3(tangentWS.xyz, bitangentWS.xyz, normalWS.xyz);

				// Shader Properties Sampling
				float4 __layer0Mask = ( TCP2_TEX2D_SAMPLE(_Mask0, _Mask0, input.pack2.xy * _Splat0_ST.xy + _Splat0_ST.zw).rgba );
				float __layer0HeightSource = ( __layer0Mask.b );
				float __layer0HeightOffset = ( _Layer0HeightOffset );
				float4 __layer1Mask = ( TCP2_TEX2D_SAMPLE(_Mask1, _Mask0, input.pack2.xy * _Splat1_ST.xy + _Splat1_ST.zw).rgba );
				float __layer1HeightSource = ( __layer1Mask.b );
				float __layer1HeightOffset = ( _Layer1HeightOffset );
				float4 __layer2Mask = ( TCP2_TEX2D_SAMPLE(_Mask2, _Mask0, input.pack2.xy * _Splat2_ST.xy + _Splat2_ST.zw).rgba );
				float __layer2HeightSource = ( __layer2Mask.b );
				float __layer2HeightOffset = ( _Layer2HeightOffset );
				float4 __layer3Mask = ( TCP2_TEX2D_SAMPLE(_Mask3, _Mask0, input.pack2.xy * _Splat3_ST.xy + _Splat3_ST.zw).rgba );
				float __layer3HeightSource = ( __layer3Mask.b );
				float __layer3HeightOffset = ( _Layer3HeightOffset );
				float4 __layer0NormalMapAddpass = ( TCP2_TEX2D_SAMPLE(_Normal0, _Normal0, input.pack2.xy * _Splat0_ST.xy + _Splat0_ST.zw).rgba );
				float4 __layer1NormalMapAddpass = ( TCP2_TEX2D_SAMPLE(_Normal1, _Normal0, input.pack2.xy * _Splat1_ST.xy + _Splat1_ST.zw).rgba );
				float4 __layer2NormalMapAddpass = ( TCP2_TEX2D_SAMPLE(_Normal2, _Normal0, input.pack2.xy * _Splat2_ST.xy + _Splat2_ST.zw).rgba );
				float4 __layer3NormalMapAddpass = ( TCP2_TEX2D_SAMPLE(_Normal3, _Normal0, input.pack2.xy * _Splat3_ST.xy + _Splat3_ST.zw).rgba );
				float4 __layer0AlbedoAddpass = ( TCP2_TEX2D_SAMPLE(_Splat0, _Splat0, input.pack2.xy * _Splat0_ST.xy + _Splat0_ST.zw).rgba );
				float4 __layer1AlbedoAddpass = ( TCP2_TEX2D_SAMPLE(_Splat1, _Splat0, input.pack2.xy * _Splat1_ST.xy + _Splat1_ST.zw).rgba );
				float4 __layer2AlbedoAddpass = ( TCP2_TEX2D_SAMPLE(_Splat2, _Splat0, input.pack2.xy * _Splat2_ST.xy + _Splat2_ST.zw).rgba );
				float4 __layer3AlbedoAddpass = ( TCP2_TEX2D_SAMPLE(_Splat3, _Splat0, input.pack2.xy * _Splat3_ST.xy + _Splat3_ST.zw).rgba );
				float4 __mainColor = ( _BaseColor.rgba );
				float __ambientIntensity = ( 1.0 );
				float __rampThreshold = ( _RampThreshold );
				float __rampSmoothing = ( _RampSmoothing );
				float __bandsCount = ( _BandsCount );
				float __bandsSmoothing = ( _BandsSmoothing );
				float4 __progressiveSketchTexture = ( TCP2_TEX2D_SAMPLE_TRIPLANAR(_ProgressiveSketchTexture, _ProgressiveSketchTexture, float4(1, 1, 1, 1) * _ProgressiveSketchTexture_ST, positionWS, normalWS).rgba );
				float __progressiveSketchSmoothness = ( _ProgressiveSketchSmoothness );
				float3 __shadowColor = ( _SColor.rgb );
				float3 __highlightColor = ( _HColor.rgb );

				// Terrain
				
				float2 terrainTexcoord0 = input.pack2.xy.xy;
				
				#if defined(_ALPHATEST_ON)
					ClipHoles(terrainTexcoord0.xy);
				#endif
				
				#if defined(TERRAIN_BASE_PASS)
				
					half4 terrain_mixedDiffuse = TCP2_TEX2D_SAMPLE(_MainTex, _MainTex, terrainTexcoord0.xy).rgba;
					half3 normalTS = half3(0.0h, 0.0h, 1.0h);
				
				#else
				
					// Sample the splat control texture generated by the terrain
					// adjust splat UVs so the edges of the terrain tile lie on pixel centers
					float2 terrainSplatUV = (terrainTexcoord0.xy * (_Control_TexelSize.zw - 1.0f) + 0.5f) * _Control_TexelSize.xy;
					half4 terrain_splat_control_0 = TCP2_TEX2D_SAMPLE(_Control, _Control, terrainSplatUV);
					half height0 = __layer0HeightSource + __layer0HeightOffset;
					half height1 = __layer1HeightSource + __layer1HeightOffset;
					half height2 = __layer2HeightSource + __layer2HeightOffset;
					half height3 = __layer3HeightSource + __layer3HeightOffset;
					HeightBasedSplatModify(terrain_splat_control_0, half4(height0, height1, height2, height3));
				
					// Calculate weights and perform the texture blending
					half terrain_weight = dot(terrain_splat_control_0, half4(1,1,1,1));
				
					#if !defined(SHADER_API_MOBILE) && defined(TERRAIN_SPLAT_ADDPASS)
						clip(terrain_weight == 0.0f ? -1 : 1);
					#endif
				
					// Normalize weights before lighting and restore afterwards so that the overall lighting result can be correctly weighted
					terrain_splat_control_0 /= (terrain_weight + 1e-3f);
				
					// Sample terrain normal maps
					half4 normal0 = __layer0NormalMapAddpass;
					half4 normal1 = __layer1NormalMapAddpass;
					half4 normal2 = __layer2NormalMapAddpass;
					half4 normal3 = __layer3NormalMapAddpass;
					#define UnpackFunction UnpackNormalScale
					half3 normalTS = UnpackFunction(normal0, _NormalScale0) * terrain_splat_control_0.r;
					normalTS += UnpackFunction(normal1, _NormalScale1) * terrain_splat_control_0.g;
					normalTS += UnpackFunction(normal2, _NormalScale2) * terrain_splat_control_0.b;
					normalTS += UnpackFunction(normal3, _NormalScale3) * terrain_splat_control_0.a;
					normalTS.z += 1e-3f; // to avoid nan after normalizing
				
				#endif // TERRAIN_BASE_PASS
				
				// Terrain normal, if using instancing and per-pixel normal map
				#if defined(UNITY_INSTANCING_ENABLED) && !defined(SHADER_API_D3D11_9X) && defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float2 terrainNormalCoords = (terrainTexcoord0.xy / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					normalWS = normalize(TCP2_TEX2D_SAMPLE(_TerrainNormalmapTexture, _TerrainNormalmapTexture, terrainNormalCoords.xy).rgb * 2 - 1);
					normalWS = mul(float4(normalWS, 0), UNITY_MATRIX_M).xyz;
				
					// take terrain normal into account when converting normal maps to world space:
					tangentWS = cross(UNITY_MATRIX_M._13_23_33, normalWS);
					tangentToWorldMatrix = half3x3(-tangentWS, cross(normalWS, tangentWS), normalWS);
				#endif

				// main texture
				half3 albedo = half3(1,1,1);
				half alpha = 1;

				#if !defined(TERRAIN_BASE_PASS)
					// Sample textures that will be blended based on the terrain splat map
					half4 splat0 = __layer0AlbedoAddpass;
					half4 splat1 = __layer1AlbedoAddpass;
					half4 splat2 = __layer2AlbedoAddpass;
					half4 splat3 = __layer3AlbedoAddpass;
				
					#define BLEND_TERRAIN_HALF4(outVariable, sourceVariable) \
						half4 outVariable = terrain_splat_control_0.r * sourceVariable##0; \
						outVariable += terrain_splat_control_0.g * sourceVariable##1; \
						outVariable += terrain_splat_control_0.b * sourceVariable##2; \
						outVariable += terrain_splat_control_0.a * sourceVariable##3;
					#define BLEND_TERRAIN_HALF(outVariable, sourceVariable) \
						half4 outVariable = dot(terrain_splat_control_0, half4(sourceVariable##0, sourceVariable##1, sourceVariable##2, sourceVariable##3));
				
					BLEND_TERRAIN_HALF4(terrain_mixedDiffuse, splat)
				
				#endif // !TERRAIN_BASE_PASS
				
				albedo = terrain_mixedDiffuse.rgb;
				alpha = terrain_mixedDiffuse.a;
				
				normalWS = normalize( mul(normalTS, tangentToWorldMatrix) );

				half3 emission = half3(0,0,0);
				
				albedo *= __mainColor.rgb;

				// main light: direction, color, distanceAttenuation, shadowAttenuation
			#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord = input.shadowCoord;
			#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
				float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
			#else
				float4 shadowCoord = float4(0, 0, 0, 0);
			#endif

			#if defined(URP_10_OR_NEWER)
				#if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
					half4 shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
				#elif !defined (LIGHTMAP_ON)
					half4 shadowMask = unity_ProbesOcclusion;
				#else
					half4 shadowMask = half4(1, 1, 1, 1);
				#endif

				Light mainLight = GetMainLight(shadowCoord, positionWS, shadowMask);
			#else
				Light mainLight = GetMainLight(shadowCoord);
			#endif

			#if defined(_SCREEN_SPACE_OCCLUSION) || defined(USE_FORWARD_PLUS) || defined(USE_CLUSTER_LIGHT_LOOP)
				float2 normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
			#endif

				// ambient or lightmap
				// Samples SH fully per-pixel. SampleSHVertex and SampleSHPixel functions
				// are also defined in case you want to sample some terms per-vertex.
				half3 bakedGI = SampleSH(normalWS);
				half occlusion = 1;

				half3 indirectDiffuse = bakedGI;
				indirectDiffuse *= occlusion * albedo * __ambientIntensity;

				half3 lightDir = mainLight.direction;
				half3 lightColor = mainLight.color.rgb;

				half atten = mainLight.shadowAttenuation * mainLight.distanceAttenuation;

				half ndl = dot(normalWS, lightDir);
				half3 ramp;
				
				half rampThreshold = __rampThreshold;
				half rampSmooth = __rampSmoothing * 0.5;
				half bandsCount = __bandsCount;
				half bandsSmoothing = __bandsSmoothing;
				ndl = saturate(ndl);
				half bandsNdl = smoothstep(rampThreshold - rampSmooth, rampThreshold + rampSmooth, ndl);
				half bandsSmooth = bandsSmoothing * 0.5;
				ramp = saturate((smoothstep(0.5 - bandsSmooth, 0.5 + bandsSmooth, frac(bandsNdl * bandsCount)) + floor(bandsNdl * bandsCount)) / bandsCount).xxx;

				// apply attenuation
				ramp *= atten;

				half3 color = half3(0,0,0);
				half3 accumulatedRamp = ramp * max(lightColor.r, max(lightColor.g, lightColor.b));
				half3 accumulatedColors = ramp * lightColor.rgb;

				// Additional lights loop
			#ifdef _ADDITIONAL_LIGHTS
				uint pixelLightCount = GetAdditionalLightsCount();

				#if USE_FORWARD_PLUS || USE_CLUSTER_LIGHT_LOOP
					// Additional directional lights in Forward+
					for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
					{
						CLUSTER_LIGHT_LOOP_SUBTRACTIVE_LIGHT_CHECK

						Light light = GetAdditionalLight(lightIndex, positionWS, shadowMask);

						#if defined(_LIGHT_LAYERS)
							if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
						#endif
						{
							half atten = light.shadowAttenuation * light.distanceAttenuation;

							#if defined(_LIGHT_LAYERS)
								half3 lightDir = half3(0, 1, 0);
								half3 lightColor = half3(0, 0, 0);
								if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
								{
									lightColor = light.color.rgb;
									lightDir = light.direction;
								}
							#else
								half3 lightColor = light.color.rgb;
								half3 lightDir = light.direction;
							#endif

							half ndl = dot(normalWS, lightDir);
							half3 ramp;
							
							ndl = saturate(ndl);
							half bandsNdl = smoothstep(rampThreshold - rampSmooth, rampThreshold + rampSmooth, ndl);
							half bandsSmooth = bandsSmoothing * 0.5;
							ramp = saturate((smoothstep(0.5 - bandsSmooth, 0.5 + bandsSmooth, frac(bandsNdl * bandsCount)) + floor(bandsNdl * bandsCount)) / bandsCount).xxx;

							// apply attenuation (shadowmaps & point/spot lights attenuation)
							ramp *= atten;

							accumulatedRamp += ramp * max(lightColor.r, max(lightColor.g, lightColor.b));
							accumulatedColors += ramp * lightColor.rgb;

						}
					}

					// Data with dummy struct used in Forward+ macro (LIGHT_LOOP_BEGIN)
					InputDataForwardPlusDummy inputData;
					inputData.normalizedScreenSpaceUV = normalizedScreenSpaceUV;
					inputData.positionWS = positionWS;
				#endif

				LIGHT_LOOP_BEGIN(pixelLightCount)
				{
					#if defined(URP_10_OR_NEWER)
						Light light = GetAdditionalLight(lightIndex, positionWS, shadowMask);
					#else
						Light light = GetAdditionalLight(lightIndex, positionWS);
					#endif
					half atten = light.shadowAttenuation * light.distanceAttenuation;

					#if defined(_LIGHT_LAYERS)
						half3 lightDir = half3(0, 1, 0);
						half3 lightColor = half3(0, 0, 0);
						if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
						{
							lightColor = light.color.rgb;
							lightDir = light.direction;
						}
					#else
						half3 lightColor = light.color.rgb;
						half3 lightDir = light.direction;
					#endif

					half ndl = dot(normalWS, lightDir);
					half3 ramp;
					
					ndl = saturate(ndl);
					half bandsNdl = smoothstep(rampThreshold - rampSmooth, rampThreshold + rampSmooth, ndl);
					half bandsSmooth = bandsSmoothing * 0.5;
					ramp = saturate((smoothstep(0.5 - bandsSmooth, 0.5 + bandsSmooth, frac(bandsNdl * bandsCount)) + floor(bandsNdl * bandsCount)) / bandsCount).xxx;

					// apply attenuation (shadowmaps & point/spot lights attenuation)
					ramp *= atten;

					accumulatedRamp += ramp * max(lightColor.r, max(lightColor.g, lightColor.b));
					accumulatedColors += ramp * lightColor.rgb;

				}
				LIGHT_LOOP_END
			#endif
			#ifdef _ADDITIONAL_LIGHTS_VERTEX
				color += input.vertexLights * albedo;
			#endif

				accumulatedRamp = saturate(accumulatedRamp);
				
				// Sketch
				#if defined(TCP2_SKETCH)
				half4 sketch = __progressiveSketchTexture;
				half4 sketchWeights = half4(0,0,0,0);
				half sketchStep = 1.0 / 5.0;
				half sketchSmooth = __progressiveSketchSmoothness;
				sketchWeights.a = smoothstep(sketchStep + sketchSmooth, sketchStep - sketchSmooth, accumulatedRamp);
				sketchWeights.b = smoothstep(sketchStep*2 + sketchSmooth, sketchStep*2 - sketchSmooth, accumulatedRamp) - sketchWeights.a;
				sketchWeights.g = smoothstep(sketchStep*3 + sketchSmooth, sketchStep*3 - sketchSmooth, accumulatedRamp) - sketchWeights.a - sketchWeights.b;
				sketchWeights.r = smoothstep(sketchStep*4 + sketchSmooth, sketchStep*4 - sketchSmooth, accumulatedRamp) - sketchWeights.a - sketchWeights.b - sketchWeights.g;
				half combinedSketch = 1.0 - dot(sketch, sketchWeights);
				
				#endif
				half3 shadowColor = (1 - accumulatedRamp.rgb) * __shadowColor;
				accumulatedRamp = accumulatedColors.rgb * __highlightColor + shadowColor;
				color += albedo * accumulatedRamp;
				#if defined(TCP2_SKETCH)
				color.rgb *= combinedSketch;
				#endif

				// apply ambient
				color += indirectDiffuse;

				color += emission;

				#if !defined(TERRAIN_BASE_PASS)
					color.rgb *= terrain_weight;
				#endif
				
				return half4(color, alpha);
			}
			ENDHLSL
		}

		// Outline
		Pass
		{
			Name "Outline"
			Tags { "LightMode" = "Outline" }
			Tags
			{
			}
			Cull Front

			HLSLPROGRAM

			#pragma vertex vertex_outline
			#pragma fragment fragment_outline

			#pragma target 3.0

			#pragma multi_compile _ TCP2_COLORS_AS_NORMALS TCP2_TANGENT_AS_NORMALS TCP2_UV1_AS_NORMALS TCP2_UV2_AS_NORMALS TCP2_UV3_AS_NORMALS TCP2_UV4_AS_NORMALS
			#pragma multi_compile _ TCP2_UV_NORMALS_FULL TCP2_UV_NORMALS_ZW
			#pragma multi_compile_instancing
			#pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap forwardadd

			ENDHLSL
		}
		// Depth & Shadow Caster Passes
		HLSLINCLUDE

		#if defined(SHADOW_CASTER_PASS) || defined(DEPTH_ONLY_PASS)

			#define fixed half
			#define fixed2 half2
			#define fixed3 half3
			#define fixed4 half4

			float3 _LightDirection;
			float3 _LightPosition;

			struct Attributes
			{
				float4 vertex   : POSITION;
				float3 normal   : NORMAL;
				float4 texcoord0 : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float4 positionCS     : SV_POSITION;
			#if defined(DEPTH_NORMALS_PASS)
				float3 normalWS : TEXCOORD0;
			#endif
				float2 pack0 : TEXCOORD1; /* pack0.xy = texcoord0 */
			#if defined(DEPTH_ONLY_PASS)
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			#endif
			};

			float4 GetShadowPositionHClip(Attributes input)
			{
				float3 positionWS = TransformObjectToWorld(input.vertex.xyz);
				float3 normalWS = TransformObjectToWorldNormal(input.normal);

				#if _CASTING_PUNCTUAL_LIGHT_SHADOW
					float3 lightDirectionWS = normalize(_LightPosition - positionWS);
				#else
					float3 lightDirectionWS = _LightDirection;
				#endif
				float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

				#if UNITY_REVERSED_Z
					positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#else
					positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#endif

				return positionCS;
			}

			Varyings ShadowDepthPassVertex(Attributes input)
			{
				Varyings output = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				#if defined(DEPTH_ONLY_PASS)
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
				#endif

				TerrainInstancing(input.vertex, input.normal, input.texcoord0.xy);

				// Texture Coordinates
				output.pack0.xy = input.texcoord0.xy;

				#if defined(DEPTH_ONLY_PASS)
					output.positionCS = TransformObjectToHClip(input.vertex.xyz);
					#if defined(DEPTH_NORMALS_PASS)
						float3 normalWS = TransformObjectToWorldNormal(input.normal);
						output.normalWS = normalWS; // already normalized in TransformObjectToWorldNormal
					#endif
				#elif defined(SHADOW_CASTER_PASS)
					output.positionCS = GetShadowPositionHClip(input);
				#else
					output.positionCS = float4(0,0,0,0);
				#endif

				return output;
			}

			half4 ShadowDepthPassFragment(
				Varyings input
	#if defined(DEPTH_NORMALS_PASS) && defined(_WRITE_RENDERING_LAYERS)
		#if UNITY_VERSION >= 60020000
				, out uint outRenderingLayers : SV_Target1
		#else
				, out float4 outRenderingLayers : SV_Target1
		#endif
	#endif
			) : SV_TARGET
			{
				#if defined(DEPTH_ONLY_PASS)
					UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
				#endif

				half3 albedo = half3(1,1,1);
				half alpha = 1;
				half3 emission = half3(0,0,0);

				#if defined(DEPTH_NORMALS_PASS)
					#if defined(_WRITE_RENDERING_LAYERS)
						#if UNITY_VERSION >= 60020000
							outRenderingLayers = EncodeMeshRenderingLayer();
						#else
							outRenderingLayers = float4(EncodeMeshRenderingLayer(GetMeshRenderingLayer()), 0, 0, 0);
						#endif
					#endif

					#if defined(URP_12_OR_NEWER)
						return float4(input.normalWS.xyz, 0.0);
					#else
						return float4(PackNormalOctRectEncode(TransformWorldToViewDir(input.normalWS, true)), 0.0, 0.0);
					#endif
				#endif

				return 0;
			}

		#endif
		ENDHLSL

		Pass
		{
			Name "ShadowCaster"
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			// using simple #define doesn't work, we have to use this instead
			#pragma multi_compile SHADOW_CASTER_PASS

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing
			#pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap forwardadd
			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			#pragma vertex ShadowDepthPassVertex
			#pragma fragment ShadowDepthPassFragment

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

			ENDHLSL
		}

		Pass
		{
			Name "DepthOnly"
			Tags
			{
				"LightMode" = "DepthOnly"
			}

			ZWrite On
			ColorMask 0

			HLSLPROGRAM

			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing
			#pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap forwardadd

			// using simple #define doesn't work, we have to use this instead
			#pragma multi_compile DEPTH_ONLY_PASS

			#pragma vertex ShadowDepthPassVertex
			#pragma fragment ShadowDepthPassFragment

			ENDHLSL
		}

		Pass
		{
			Name "DepthNormals"
			Tags
			{
				"LightMode" = "DepthNormals"
			}

			ZWrite On

			HLSLPROGRAM
			#pragma exclude_renderers gles gles3 glcore
			#pragma target 2.0

			#pragma multi_compile_instancing
			#pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap forwardadd

			// using simple #define doesn't work, we have to use this instead
			#pragma multi_compile DEPTH_ONLY_PASS
			#pragma multi_compile DEPTH_NORMALS_PASS

			#pragma vertex ShadowDepthPassVertex
			#pragma fragment ShadowDepthPassFragment

			ENDHLSL
		}

		// Scene picking for terrain shader
		UsePass "Hidden/Nature/Terrain/Utilities/PICKING"

		// Scene selection and picking passes
		Pass
		{
			Name "SceneSelectionPass"
			Tags
			{
				"LightMode" = "SceneSelectionPass"
			}

			HLSLPROGRAM
			#pragma exclude_renderers gles gles3 glcore
			#pragma target 2.0

			#pragma multi_compile_instancing
			#pragma multi_compile DEPTH_ONLY_PASS

			#pragma vertex ShadowDepthPassVertex
			#pragma fragment SceneSelectionFragment

			int _ObjectId;
			int _PassValue;

			half4 SceneSelectionFragment(Varyings input) : SV_Target
			{
				ShadowDepthPassFragment(input);
				return float4(_ObjectId, _PassValue, 1, 1);
			}

			ENDHLSL
		}

		Pass
		{
			Name "ScenePickingPass"
			Tags
			{
				"LightMode" = "Picking"
			}

			HLSLPROGRAM
			#pragma exclude_renderers gles gles3 glcore
			#pragma target 2.0

			#pragma multi_compile_instancing
			#pragma multi_compile DEPTH_ONLY_PASS

			#pragma vertex ShadowDepthPassVertex
			#pragma fragment ScenePickingFragment

			float4 _SelectionID;

			half4 ScenePickingFragment(Varyings input) : SV_Target
			{
				ShadowDepthPassFragment(input);
				return _SelectionID;
			}

			ENDHLSL
		}
	}

	FallBack "Hidden/InternalErrorShader"
	CustomEditor "ToonyColorsPro.ShaderGenerator.MaterialInspector_SG2"
}

