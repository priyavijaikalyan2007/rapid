// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 97c88f3f-0875-463a-bdf1-777308217275
// Created: 2026
// COMPONENT: ResourceRedirectPolicy
// PURPOSE: Defines the ResourceRedirectPolicy domain values and their contracts.
// RELATES: [[CropPrint]]
// FLOW: Native application -> ResourceRedirectPolicy -> local result.

import Foundation

/// Rejects insecure redirects before URLSession follows them.
final class ResourceRedirectPolicy: NSObject, URLSessionTaskDelegate
{
    /// HTTPS redirects remain available for public resource hosts and their content delivery networks.
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    )
    {
        guard let address = request.url
        else
        {
            completionHandler(nil)
            return
        }
        do
        {
            try ResourceDownloadPolicy.validateAddress(address)
            completionHandler(request)
        }
        catch
        {
            completionHandler(nil)
        }
    }
}
