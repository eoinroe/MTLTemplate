import Foundation
import Metal
import MetalKit

protocol RenderDestinationProvider {
    var currentRenderPassDescriptor: MTLRenderPassDescriptor? { get }
    var currentDrawable: CAMetalDrawable? { get }
    var colorPixelFormat: MTLPixelFormat { get set }
    var sampleCount: Int { get set }
}

class Renderer {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    
    var renderDestination: RenderDestinationProvider
    
    var computePipeline: MTLComputePipelineState!
    
    var renderPipeline: MTLRenderPipelineState!
    
    init(metalDevice device: MTLDevice, renderDestination: RenderDestinationProvider) {
        self.device = device
        self.renderDestination = renderDestination
        
        // Perform one-time setup of the Metal objects.
        loadMetal()
    }
    
    func update() {
        // Create a new command buffer for each renderpass to the current drawable.
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            commandBuffer.label = "MyCommandBuffer"
            
            if let renderPassDescriptor = renderDestination.currentRenderPassDescriptor,
               let currentDrawable = renderDestination.currentDrawable {
                
                if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                    
                    // Set a label to identify this render pass in a captured Metal frame.
                    renderEncoder.label = "HelloWorldRenderEncoder"
                    
                    renderEncoder.setRenderPipelineState(renderPipeline)
                    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                    
                    // Finish encoding commands.
                    renderEncoder.endEncoding()
                }
                
                // encodeComputeKernelToCommandBuffer(commandBuffer: commandBuffer, drawable: currentDrawable)
                
                // Schedule a present once the framebuffer is complete using the current drawable.
                commandBuffer.present(currentDrawable)
            }
            
            // Finalize rendering here & push the command buffer to the GPU.
            commandBuffer.commit()
        }
    }
    
    func encodeComputeKernelToCommandBuffer(commandBuffer: MTLCommandBuffer, drawable: CAMetalDrawable) {
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        computeEncoder.setComputePipelineState(computePipeline)
        
        let w = computePipeline.threadExecutionWidth
        let h = computePipeline.maxTotalThreadsPerThreadgroup / w
        
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
        
        let threadsPerGrid = MTLSize(width: drawable.texture.width,
                                     height: drawable.texture.height,
                                     depth: 1)
        
        computeEncoder.dispatchThreadgroups(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()
    }
    
    func loadMetal() {
        // Load all the shader files with a metal file extension in the project.
        let defaultLibrary = device.makeDefaultLibrary()!
        
        guard let vertexFunction = defaultLibrary.makeFunction(name: "base_vertex"),
              let fragmentFunction = defaultLibrary.makeFunction(name: "base_fragment") else {
            fatalError("Couldn't create the shader functions.")
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.sampleCount = renderDestination.sampleCount
        descriptor.colorAttachments[0].pixelFormat = renderDestination.colorPixelFormat
        
        do {
            try renderPipeline = device.makeRenderPipelineState(descriptor: descriptor)
        } catch let error {
            print("Failed to create the compute pipeline state, error", error, separator: ": ")
        }
        
        guard let kernelFunction = defaultLibrary.makeFunction(name: "gradient") else {
            fatalError("Couldn't create the kernel function.")
        }
        
        do {
            try computePipeline = device.makeComputePipelineState(function: kernelFunction)
        } catch let error {
            print("Failed to create the compute pipeline state, error \(error)")
        }
        
        // Create the command queue for one frame of rendering work.
        commandQueue = device.makeCommandQueue()
    }
}
