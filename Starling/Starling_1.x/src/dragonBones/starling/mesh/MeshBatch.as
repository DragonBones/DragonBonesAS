package dragonBones.starling.mesh 
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.utils.Dictionary;
	
	import dragonBones.starling.mesh.Mesh;
	import dragonBones.starling.mesh.MeshArmature;
	
	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.errors.MissingContextError;
	import starling.events.Event;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;
	import starling.utils.VertexData;
	/**
	 * ...
	 * @author sukui
	 */
	public class MeshBatch 
	{	
        public static const MAX_NUM_VERTEX:int = 16383;
        
        private static const QUAD_PROGRAM_NAME:String = "QB_q";
        
        private var mNumMeshs:int;
        private var mNumVertex:int;
		private var mNumTriangles:int;
		private var mParentAlpha:Number;
		private var mSupport:RenderSupport;
		
        private var mSyncRequired:Boolean;
        private var mBatchable:Boolean;
        private var mForceTinted:Boolean;
        private var mOwnsTexture:Boolean;

        private var mTinted:Boolean;
        private var mTexture:Texture;
        private var mSmoothing:String;
        
        private var mVertexBuffer:VertexBuffer3D;
        private var mIndexData:Vector.<uint>;
        private var mIndexBuffer:IndexBuffer3D;
        
		public var blendMode:String;
        /** The raw vertex data of the quad. After modifying its contents, call
         *  'onVertexDataChanged' to upload the changes to the vertex buffers. Don't change the
         *  size of this object manually; instead, use the 'capacity' property of the QuadBatch. */
        protected var mVertexData:VertexData;

        /** Helper objects. */
        private static var sHelperMatrix:Matrix = new Matrix();
        private static var sRenderAlpha:Vector.<Number> = new <Number>[1.0, 1.0, 1.0, 1.0];
        private static var sProgramNameCache:Dictionary = new Dictionary();
		
		public function MeshBatch() 
		{
			mVertexData = new VertexData(0, true);
            mIndexData = new <uint>[];
            mNumMeshs = 0;
			mNumTriangles = 0;
			mNumVertex = 0;
            mTinted = false;
            mSyncRequired = false;
            mBatchable = false;
            mForceTinted = false;
            mOwnsTexture = false;

            // Handle lost context. We use the conventional event here (not the one from Starling)
            // so we're able to create a weak event listener; this avoids memory leaks when people 
            // forget to call "dispose" on the QuadBatch.
            Starling.current.stage3D.addEventListener(Event.CONTEXT3D_CREATE, 
                                                      onContextCreated, false, 0, true);
		}
		
		 /** Disposes vertex- and index-buffer. */
        public function dispose():void
        {
            Starling.current.stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            destroyBuffers();
            
            mVertexData.numVertices = 0;
            mIndexData.length = 0;
            mNumMeshs = 0;
			mNumVertex = 0;

            if (mTexture && mOwnsTexture)
                mTexture.dispose();
            
            super.dispose();
        }
		
		private function onContextCreated(event:Object):void
        {
            createBuffers();
        }
		
		/** Call this method after manually changing the contents of 'mVertexData'. */
        protected function onVertexDataChanged():void
        {
            mSyncRequired = true;
        }
		
		private function createBuffers():void
        {
            destroyBuffers();

            var numVertices:int = mVertexData.numVertices;
            var numIndices:int = mIndexData.length;
            var context:Context3D = Starling.context;

            if (numVertices == 0) return;
            if (context == null)  throw new MissingContextError();
            
            mVertexBuffer = context.createVertexBuffer(numVertices, VertexData.ELEMENTS_PER_VERTEX);
            mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, numVertices);
            
            mIndexBuffer = context.createIndexBuffer(mNumTriangles * 3);
            mIndexBuffer.uploadFromVector(mIndexData, 0, mNumTriangles * 3);
			
            mSyncRequired = false;
        }
		
		private function destroyBuffers():void
        {
            if (mVertexBuffer)
            {
                mVertexBuffer.dispose();
                mVertexBuffer = null;
            }

            if (mIndexBuffer)
            {
                mIndexBuffer.dispose();
                mIndexBuffer = null;
            }
        }
		
		 /** Uploads the raw data of all batched quads to the vertex buffer. */
        private function syncBuffers():void
        {
            if (mVertexBuffer == null)
            {
                createBuffers();
            }
            else
            {
                // as last parameter, we could also use 'mNumQuads * 4', but on some
                // GPU hardware (iOS!), this is slower than updating the complete buffer.
                mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, mVertexData.numVertices);
				mIndexBuffer.uploadFromVector(mIndexData, 0, mNumTriangles * 3);
                mSyncRequired = false;
            }
        }
		
		public function render(mesh:MeshImage, support:RenderSupport, parentAlpha:Number):void
        {
			if (mesh.meshData.skinned)
			{
				addMesh(mesh, parentAlpha, mesh.texture,smoothing);
			}
			else
			{
				addMesh(mesh, parentAlpha, mesh.texture,smoothing,support.modelViewMatrix);
			}
			
			mParentAlpha = parentAlpha;
			mSupport = support;
			if (!(mesh.parent is MeshArmature))
			{
				flush();
			}
        }
		
		public function flush():void
		{
			if (mNumMeshs)
            {
                mSupport.raiseDrawCount();
                renderCustom(mSupport.projectionMatrix3D, mParentAlpha, mSupport.blendMode);
            }
		}
		/** Renders the current batch with custom settings for model-view-projection matrix, alpha 
         *  and blend mode. This makes it possible to render batches that are not part of the 
         *  display list. */ 
        public function renderCustom(mvpMatrix:Matrix3D, parentAlpha:Number=1.0,
                                     blendMode:String=null):void
        {
            if (mNumMeshs == 0) return;
            if (mSyncRequired) syncBuffers();
            
            var pma:Boolean = mVertexData.premultipliedAlpha;
            var context:Context3D = Starling.context;
            var tinted:Boolean = mTinted || (parentAlpha != 1.0);
            
            sRenderAlpha[0] = sRenderAlpha[1] = sRenderAlpha[2] = pma ? parentAlpha : 1.0;
            sRenderAlpha[3] = parentAlpha;
            
            RenderSupport.setBlendFactors(pma, blendMode ? blendMode : "normal");
            
            context.setProgram(getProgram(tinted));
            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, sRenderAlpha, 1); //vc0
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, mvpMatrix, true); //vc1
            context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, //va0
                                      Context3DVertexBufferFormat.FLOAT_2); 
            
            if (mTexture == null || tinted)
			{
				
                context.setVertexBufferAt(1, mVertexBuffer, VertexData.COLOR_OFFSET, //va1
                                          Context3DVertexBufferFormat.FLOAT_4);
			}
            
            if (mTexture)
            {
                context.setTextureAt(0, mTexture.base); //fs0
                context.setVertexBufferAt(2, mVertexBuffer, VertexData.TEXCOORD_OFFSET, //va2
                                          Context3DVertexBufferFormat.FLOAT_2);
            }
            
            context.drawTriangles(mIndexBuffer, 0, mNumTriangles);
            
			reset();
            if (mTexture)
            {
                context.setTextureAt(0, null);
                context.setVertexBufferAt(2, null);
            }
            
            context.setVertexBufferAt(1, null);
            context.setVertexBufferAt(0, null);
        }
		
		/** Resets the batch. The vertex- and index-buffers remain their size, so that they
         *  can be reused quickly. */
        public function reset():void
        {
            if (mTexture && mOwnsTexture)
                mTexture.dispose();

            mNumVertex = 0;
			mNumMeshs = 0;
			mNumTriangles = 0;
			mIndexData.length = 0;
            mTexture = null;
            mSmoothing = null;
            mSyncRequired = true;
        }
		
		public function addMesh(mesh:Mesh, parentAlpha:Number=1.0, texture:Texture=null, 
                                smoothing:String=null, modelViewMatrix:Matrix=null, 
                                blendMode:String = null):void
		{
			if (modelViewMatrix == null)
			{
				//是skinned mesh 由rig的骨骼坐标控制和其slot的坐标没有关系了，
				//但骨骼的坐标只是相对其根骨骼的坐标，所以这里要乘上，mesh父的matrix
                modelViewMatrix = mesh.parent.transformationMatrix;
			}
            
			const numVertex:uint = mesh.meshData.numVertex;
			const numTriangle:uint = mesh.meshData.numTriangle;
			
            var alpha:Number = parentAlpha * mesh.alpha;
            
            
			if (mNumVertex + numVertex > MAX_NUM_VERTEX)
			{
				flush();
			}
			if (mTexture != null && texture != null && mTexture.base != texture.base)
			{
				flush();
			}
			
			var vertexID:int = mNumVertex;
			var indexID:int = mNumTriangles * 3;
			
			mNumTriangles += numTriangle;
			
            if (mNumVertex + numVertex > mVertexData.numVertices)
			{
				expand(mNumVertex + numVertex - mVertexData.numVertices);
			}
			mNumVertex += numVertex;
            if (mNumMeshs == 0) 
            {
                this.blendMode = blendMode ? blendMode : mesh.blendMode;
                mTexture = texture;
                mTinted = mForceTinted || mesh.tinted || parentAlpha != 1.0;
                mSmoothing = smoothing;
                mVertexData.setPremultipliedAlpha(mesh.premultipliedAlpha);
            }
			for (var i:int = 0, len:int = mesh.meshData.triangles.length; i < len; i++)
			{
				mIndexData[indexID + i] = (mesh.meshData.triangles[i] + vertexID);
			}
            mesh.copyVertexDataTransformedTo(mVertexData, vertexID, modelViewMatrix);
            
            if (alpha != 1.0)
			{
                mVertexData.scaleAlpha(vertexID, alpha, numVertex);
			}

            mSyncRequired = true;
            mNumMeshs++;
		}
		
		private function expand(size:int):void
        {
            if (this.capacity + size >= MAX_NUM_VERTEX)
			{
                throw new Error("Exceeded maximum number of quads!");
			}
			mIndexData.length = mNumTriangles * 3;
            this.capacity += size;
        }
		
		private function getProgram(tinted:Boolean):Program3D
        {
            var target:Starling = Starling.current;
            var programName:String = QUAD_PROGRAM_NAME;
            
            if (mTexture)
                programName = getImageProgramName(tinted, mTexture.mipMapping, 
                    mTexture.repeat, mTexture.format, mSmoothing);
            
            var program:Program3D = target.getProgram(programName);
            
            if (!program)
            {
                // this is the input data we'll pass to the shaders:
                // 
                // va0 -> position
                // va1 -> color
                // va2 -> texCoords
                // vc0 -> alpha
                // vc1 -> mvpMatrix
                // fs0 -> texture
                
                var vertexShader:String;
                var fragmentShader:String;

                if (!mTexture) // Quad-Shaders
                {
                    vertexShader =
                        "m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace
                        "mul v0, va1, vc0 \n";  // multiply alpha (vc0) with color (va1)
                    
                    fragmentShader =
                        "mov oc, v0       \n";  // output color
                }
                else // Image-Shaders
                {
                    vertexShader = tinted ?
                        "m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace
                        "mul v0, va1, vc0 \n" + // multiply alpha (vc0) with color (va1)
                        "mov v1, va2      \n"   // pass texture coordinates to fragment program
                        :
                        "m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace
                        "mov v1, va2      \n";  // pass texture coordinates to fragment program
                    
                    fragmentShader = tinted ?
                        "tex ft1,  v1, fs0 <???> \n" + // sample texture 0
                        "mul  oc, ft1,  v0       \n"   // multiply color with texel color
                        :
                        "tex  oc,  v1, fs0 <???> \n";  // sample texture 0
                    
                    fragmentShader = fragmentShader.replace("<???>",
                        RenderSupport.getTextureLookupFlags(
                            mTexture.format, mTexture.mipMapping, mTexture.repeat, smoothing));
                }
                
                program = target.registerProgramFromSource(programName,
                    vertexShader, fragmentShader);
            }
            
            return program;
        }
		
		private static function getImageProgramName(tinted:Boolean, mipMap:Boolean=true, 
                                                    repeat:Boolean=false, format:String="bgra",
                                                    smoothing:String="bilinear"):String
        {
            var bitField:uint = 0;
            
            if (tinted) bitField |= 1;
            if (mipMap) bitField |= 1 << 1;
            if (repeat) bitField |= 1 << 2;
            
            if (smoothing == TextureSmoothing.NONE)
                bitField |= 1 << 3;
            else if (smoothing == TextureSmoothing.TRILINEAR)
                bitField |= 1 << 4;
            
            if (format == Context3DTextureFormat.COMPRESSED)
                bitField |= 1 << 5;
            else if (format == "compressedAlpha")
                bitField |= 1 << 6;
            
            var name:String = sProgramNameCache[bitField];
            
            if (name == null)
            {
                name = "QB_i." + bitField.toString(16);
                sProgramNameCache[bitField] = name;
            }
            
            return name;
        }
		
		public function get capacity():int 
		{ 
			return mVertexData.numVertices;
		}
		
        public function set capacity(value:int):void
        {
            var oldCapacity:int = capacity;
            
            if (value == oldCapacity) return;
            else if (value == 0) throw new Error("Capacity must be > 0");
            else if (value > MAX_NUM_VERTEX) value = MAX_NUM_VERTEX;
            
            mVertexData.numVertices = value;

            destroyBuffers();
            mSyncRequired = true;
        }
		
		public function get smoothing():String 
		{
			return mSmoothing;
		}
		
	}

}