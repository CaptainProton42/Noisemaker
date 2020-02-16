shader_type spatial;

render_mode skip_vertex_transform, unshaded;

/* Coordinates of the cloud box boundaries. */
uniform vec3 bMin;
uniform vec3 bMax;

/* Cloud parameters. */
uniform vec3 windDirection = vec3(1.0f, 0.0f, 0.0f);
uniform float offset : hint_range(0.0f, 1.0f);
uniform float cloudScale : hint_range(0.1, 100.0);
uniform int numSteps : hint_range(1, 100);
uniform int numStepsLight : hint_range(1, 50);
uniform float lightAbsorptionTowardsSun : hint_range(0.0, 10.0);
uniform float cloudAbsorption : hint_range(0.0, 10.0);
uniform float darknessThreshold : hint_range(0.0, 1.0);
uniform float densityMultiplier : hint_range(0.1, 10.0);
uniform float densityOffset : hint_range(-1.0, 1.0);
uniform float phaseVal : hint_range(0.1, 10.0);
uniform vec3 noiseWeights = vec3(1.0f, 1.0f, 1.0f);
uniform float gradientThreshold : hint_range(0.0f, 1.0f);
uniform bool enableDetail = true;
uniform float detailScale : hint_range(0.1f, 10.0f);
uniform vec3 detailWindDirection = vec3(1.0f, 0.0f, 0.0f);
uniform float detailMultiplier : hint_range(0.0f, 1.0f);
uniform float detailOffset : hint_range(0.0f, 1.0f);
uniform vec3 detailWeights;

/* World information. */
uniform vec3 sunDirection; // Direction of the sun in world coordinates.
uniform vec4 sunColor : hint_color; // Color of the sun.

/* Noise samplers. */
uniform sampler3D volume;
uniform sampler3D detail;

/* Set the quad to always be in front of the camera. */
void vertex()
{
	PROJECTION_MATRIX = mat4(1.0);
}

/* Density sampler. */
float sampleDensity(vec3 position)
{
	vec3 size = bMax - bMin;
	float heightPercent = (position.y - bMin.y) / size.y;
	float heightGradient;
	if (gradientThreshold > 0.95f) heightGradient = 1.0f;
	else heightGradient = 1.0f - clamp((heightPercent - gradientThreshold) / (1.0f - gradientThreshold), 0.0f, 1.0f);
	vec3 normalizedNoiseWeights = noiseWeights / length(noiseWeights);
	vec3 samplePosition = mod(position.xyz / cloudScale + windDirection*offset, 1.0f);
	float shapeFBM = dot(1.0f - texture(volume, samplePosition).rgb, normalizedNoiseWeights) * heightGradient + densityOffset;
	float baseShapeDensity = max(0, shapeFBM);
	
	//return baseShapeDensity * densityMultiplier;
	
	if (enableDetail && baseShapeDensity > 0.0f)
	{
		vec3 detailSamplePos =  mod(position.xyz / detailScale + detailWindDirection*detailOffset, 1.0f);
		vec3 detailNoise = 1.0f - texture(detail, detailSamplePos).rgb;
		vec3 normalizedDetailWeights = detailWeights / length(detailWeights);
		float detailFBM = dot(detailNoise, normalizedDetailWeights);
		float detailErodeWeight = (1.0f - shapeFBM) * (1.0f - shapeFBM) * (1.0f - shapeFBM);
		float cloudDensity = baseShapeDensity - (1.0f - detailFBM) * detailErodeWeight * detailMultiplier;
		return cloudDensity * densityMultiplier;
	}
	
	return baseShapeDensity * densityMultiplier;
}

/* Box intersector. */
vec2 rayBoxDst(vec3 boundsMin, vec3 boundsMax, vec3 rayOrigin, vec3 rayDir)
{
	vec3 t0 = (boundsMin - rayOrigin) / rayDir;
	vec3 t1 = (boundsMax - rayOrigin) / rayDir;
	vec3 tmin = min(t0, t1);
	vec3 tmax = max(t0, t1);
	
	float dstA = max(max(tmin.x, tmin.y), tmin.z);
	float dstB = min(tmax.x, min(tmax.y, tmax.z));
	
	float dstToBox = max(0, dstA);
	float dstInBox = max(0, dstB - dstToBox);

	return vec2(dstToBox, dstInBox);
}

/* Calculate how much sunlight reaches the given position in the cloud. */
float lightmarch(vec3 position)
{
	float dstInBox = rayBoxDst(bMin, bMax, position, normalize(sunDirection)).y;
	
	float stepSize = dstInBox / float(numStepsLight);
	float totalDensity = 0.0f;
	
	for (int step = 0; step < numStepsLight; ++step)
	{
		position += sunDirection * stepSize;
		totalDensity += max(0, sampleDensity(position) * stepSize);
	}
	float transmittance = exp(-totalDensity * lightAbsorptionTowardsSun);
	return darknessThreshold + transmittance * (1.0 - darknessThreshold);
}

// Raymarching shader.
void fragment()
{
	vec3 rayOrigin = (CAMERA_MATRIX * vec4(0.0f, 0.0f, 0.0f, 1.0f)).xyz;
	vec3 rayDir = normalize((CAMERA_MATRIX * INV_PROJECTION_MATRIX * vec4(2.0f*SCREEN_UV - 1.0f, 1.0f,1.0f)).xyz);
	
	vec2 rayBoxInfo = rayBoxDst(bMin, bMax, rayOrigin, rayDir);
	float dstToBox = rayBoxInfo.x;
	float dstInBox = rayBoxInfo.y;
	
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = length(view.xyz); // Eye distance.
	
	float dstTravelled = 0.0f;
	float lightEnergy = 0.0f;
	float transmittance = 1.0f;
	float maxDst = min(linear_depth - dstToBox, dstInBox);
	
	/* Putting this here improves visual quality dramatically
	even for low step numbers while keeping computational complexity
	consistent. */
	float stepSize = maxDst / float(numSteps);
	
	while (dstTravelled < maxDst)
	{
		vec3 rayPos = rayOrigin + rayDir * (dstToBox + dstTravelled);
		float density = sampleDensity(rayPos);
		if (density > 0.0f)
		{
			float lightTransmittance = lightmarch(rayPos);
			lightEnergy += density * stepSize * transmittance * lightTransmittance * phaseVal;
			transmittance *= exp(-density * stepSize * cloudAbsorption);
			
			if (transmittance < 0.01) break;
		}
		dstTravelled += stepSize;
	}

	vec3 backgroundCol = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	vec3 cloudCol = lightEnergy * sunColor.rgb;
	ALBEDO = backgroundCol * transmittance + cloudCol;
}