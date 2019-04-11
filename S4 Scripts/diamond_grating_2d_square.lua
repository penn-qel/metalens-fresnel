-- In a 1D pattern, the pattern should be specified only with rectangles.
-- The y-dimension of the rectangles is ignored.


inputs=S4.arg;

t = {} 
index = 1;

for w in string.gmatch(inputs,"%d+.%d+") do
	t[index]=w 
	index=index+1
end

R=t[1]; --tonumber(inputs:sub(2,5));

print('\n' .. 'R = ' .. t[1])

Per=t[2]; --tonumber(inputs:sub(7,10)); 

print('Per = ' .. t[2])

height=t[3];

print('height = ' .. t[3])

G=tonumber(t[4]); --tonumber(inputs:sub(12,14));

print('G = ' .. t[4] .. '\n')

_, _, opts, _ = string.find(inputs,"(%a+)")

lambda0 = 0.7;

S = S4.NewSimulation()
S:SetLattice({Per,0}, {0,Per}) -- square lattice
S:SetNumG(G)
S:SetFrequency(1/lambda0)

-- Material definition
S:AddMaterial("Vacuum", {1,0})
S:AddMaterial("Diamond",{5.76,0})

S:AddLayer('AirAbove',0,'Vacuum')
S:AddLayer('Slab', height, 'Vacuum')
--S:SetLayerPatternRectangle('Slab',        -- which layer to alter
 --                             'Diamond',     -- material in rectangle
--	                       {0,0},         -- center
--	                       0,             -- tilt angle (degrees)
--	                       {HW, 0}) -- half-widths

S:SetLayerPatternCircle('Slab',   -- which layer to alter
                        'Diamond', -- material in circle
	                    {0,0},    -- center
	                    R)      -- radius

S:AddLayer('Substrate', 0, 'Diamond')

-- E polarized along the grating periodicity direction
S:SetExcitationPlanewave(
	{0,0}, -- incidence angles (spherical coordinates: phi in [0,180], theta in [0,360])
	{1,0},  -- s-polarization amplitude and phase (in degrees)
	{0,0})  -- p-polarization amplitude and phase

--S:UsePolarizationDecomposition()

-- backward should be zero
forward, backward = S:GetAmplitudes('Substrate', -- layer in which to get
		                                 0)          -- z-offset
--Ur,Ui = S:GetLayerElectricEnergyDensityIntegral('Slab')
--print('Ur\tUi')
--print(Ur .. '\t' .. Ui)
--print(forward[1][1])
--print(forward[1][2])
--print(backward[1][1])
--print(backward[1][2])
print('m\treal(U2+)\timag(U2+)\treal(U2-)\timag(U2-)') 
for key,value in pairs(forward) do 
	print(key .. '\t' .. forward[key][1] .. '\t' .. forward[key][2] .. '\t' .. backward[key][1] .. '\t' .. backward[key][2]);
end

io.stderr:write('\n')

-- Output power in each diffracted order
if (opts == 'Pow') then
	Pow = S:GetPowerFluxByOrder('Substrate', 0)
	
	io.stderr:write('m\treal(S2+)\treal(S2-)\timag(S2+)\timag(S2-)\n')
	for key,value in pairs(Pow) do
		io.stderr:write(key .. '\t' .. Pow[key][1] .. '\t' .. Pow[key][2] .. '\t' .. Pow[key][3] .. '\t' .. Pow[key][4] .. '\t' .. '\n');
	end

	io.stderr:write('\n')
end

-- Output epsilon
if (opts == 'eps') then
	io.stderr:write('x = -Per/2:0.01:Per/2\n')
	io.stderr:write('y = -Per/2:0.01:Per/2\n')
	io.stderr:write('z = -2:.05:2\n')
	io.stderr:write('x\ty\tz\treal(epsilon)\timag(epsilon)\n')
	for z=-2,2,.05 do
		for y=-Per/2,Per/2,0.01 do
			for x=-Per/2,Per/2,0.01 do
				epsr,epsi = S:GetEpsilon({x,y,z}); -- returns real and imag parts
				io.stderr:write(x .. '\t' .. y .. '\t' .. z .. '\t' .. epsr .. '\t' .. epsi .. '\n')
			end
		end
		io.stderr:write('\n')
	end
end

-- Output electric fields
if (opts == 'fields') then
	io.stderr:write('x = -Per/2:0.01:Per/2\n')
	io.stderr:write('y = -1.0:0.02:11.0\n')
	io.stderr:write('x\ty\treal(Hx)\timag(Hx)\treal(Ey)\timag(Ey)\treal(Hz)\timag(Hz)\n')
	for x=-Per/2,Per/2,0.01 do
		for y=-0.5,2.0,0.02 do
			exr,eyr,ezr,exi,eyi,ezi = S:GetEField({x,0,y})
			hxr,hyr,hzr,hxi,hyi,hzi = S:GetHField({x,0,y})
			io.stderr:write(x .. '\t' .. y .. '\t' .. hxr .. '\t' .. hxi .. '\t' .. hyr .. '\t' .. hyi .. '\t' .. hzr .. '\t' .. hzi .. '\t' .. exr .. '\t' .. exi .. '\t' .. eyr .. '\t' .. eyi .. '\t' .. ezr .. '\t' .. ezi .. '\n')
		end
		io.stderr:write('\n')
	end
end

