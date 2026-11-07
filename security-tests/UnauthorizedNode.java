import org.jgroups.JChannel;

// Tries to join the cluster and reports the view it obtained. It sends no application data.
public class UnauthorizedNode {

	public static void main(String[] args) throws Exception {
		String stack = args[0];
		String clusterName = args[1];

		try (JChannel channel = new JChannel(stack)) {
			channel.setName("unauthorized-node");

			try {
				channel.connect(clusterName);
			}
			catch (Exception exception) {
				System.out.println("RESULT REJECTED " + exception);

				return;
			}

			Thread.sleep(45_000);

			int size = channel.getView().size();

			System.out.println("VIEW " + channel.getView());
			System.out.println(size > 1 ? "RESULT JOINED" : "RESULT ALONE");
		}
	}

}
